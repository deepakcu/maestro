
`timescale 1ns/1ps

module pipeline #(
	parameter DEFAULT_READ_LENGTH = 32,
        parameter DATA_WIDTH = 32,
        parameter DDR_BASE = 0, 
        parameter DDR_SIZE = 1073741824, //1Gb
        parameter ADDRESS_WIDTH = 31,
	parameter MAX_NUM_PROCS = 4,
	parameter PROC_ID = 0,
	parameter PROCESS_EXTERNAL_UPDATES =0,
	parameter EXT_PROCESSOR=0
) (
        input 			clk,
        input 			reset,

	//write interface b/w update unit and main memory
	output wire 				wr_control_fixed_location,
	output reg [30:0]       		wr_control_write_base,
        output reg [30:0]       		wr_control_write_length,
        output reg              		wr_control_go,
        input wire              		wr_control_done,

	output reg 				wr_user_write_buffer,
	output reg [255:0] 			wr_user_buffer_data,
	input wire 				wr_user_buffer_full,
	
	//read interface b/w update unit and main memory
	output wire			      	control_fixed_location,
	output reg [ADDRESS_WIDTH-1:0]        	control_read_base,	
	output reg [ADDRESS_WIDTH-1:0]         	control_read_length,
	output reg                             	control_go,
	input wire 			       	control_done,

	output reg                             	user_read_buffer,
	input wire 				user_data_available,
	input [255:0] 				user_buffer_data,

	//read interface b/w link unit and main memory
	output wire			      	link_control_fixed_location,
	output reg [ADDRESS_WIDTH-1:0]        	link_control_read_base,	
	output reg [ADDRESS_WIDTH-1:0]         	link_control_read_length,
	output reg                             	link_control_go,
	input wire 			       	link_control_done,

	output reg                             	link_user_read_buffer,
	input wire 				link_user_data_available,
	input [255:0] 				link_user_buffer_data,

	
	//interface b/w processor and cache controller
	output reg [31:0] 			proc_key,
	output reg 				proc_obtain_key,
	input wire 				proc_key_grant,
	input wire				proc_key_blocked,
	output reg 				proc_key_release,
	input	 				proc_key_release_ack,
	input					locks_available,

	//interface b/w update unit and top k selection circuit
	input 					start_key_process,
	output 					start_key_selection,


	//misc status signals to update unit
	input wire [31:0]                       filter_threshold,
	input [31:0]				threshold,
	input [31:0]				log_2_num_workers_in,
	input [31:0]				num_keys,
	input [31:0]				shard_id,
	input [3:0]    				max_fpga_procs,
	input	       				algo_selection,
	
	//external fifo 
	output [63:0] 				ext_fifo_data,
	output        				ext_fifo_wrreq,
	input         				ext_fifo_full,
	input					process_ext_updates,

	//rx fifo
	input [63:0]				rx_ext_update_q,
	output 					rx_ext_update_rdreq,
	input					rx_ext_update_empty,

	output wire [31:0] 			iteration_accum_value,
	input wire				start_update

);

function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
endfunction // log2

/////////////   Pipeline ///////////////


localparam KEY_WIDTH=32;
localparam MSG_WIDTH=32;
localparam MOD_BIT_WIDTH=1;
localparam FILTER_BIT_WIDTH=1;
localparam KEY_RECORD_WIDTH=256;

localparam LINK_GEN_FIFO_WIDTH		=KEY_WIDTH+MSG_WIDTH;
localparam GEN_LOCK_FIFO_WIDTH		=LINK_GEN_FIFO_WIDTH+MOD_BIT_WIDTH;
localparam LOCK_READ_FIFO_WIDTH		=GEN_LOCK_FIFO_WIDTH;
localparam READ_COMPUTE_FIFO_WIDTH	=MOD_BIT_WIDTH+FILTER_BIT_WIDTH+MSG_WIDTH+KEY_RECORD_WIDTH;
localparam COMPUTE_WRITE_FIFO_WIDTH	=FILTER_BIT_WIDTH+KEY_RECORD_WIDTH;
localparam COMPUTE_LINK_FIFO_WIDTH	=KEY_WIDTH*3;
localparam UPDATE_MODE			=0;
localparam ACCUM_MODE			=1;

wire [LINK_GEN_FIFO_WIDTH-1:0]  link_gen_fifo_data;
wire				link_gen_fifo_empty;
wire				link_gen_fifo_rdreq;
wire [LINK_GEN_FIFO_WIDTH-1:0] 	link_gen_fifo_q;
wire				link_gen_fifo_full;
wire				link_gen_fifo_wrreq;

wire [GEN_LOCK_FIFO_WIDTH-1:0]  gen_lock_fifo_data;
wire				gen_lock_fifo_empty;
wire				gen_lock_fifo_rdreq;
wire [GEN_LOCK_FIFO_WIDTH-1:0] 	gen_lock_fifo_q;
wire				gen_lock_fifo_full;
wire				gen_lock_fifo_wrreq;

wire [LOCK_READ_FIFO_WIDTH-1:0] lock_read_fifo_data;
wire				lock_read_fifo_empty;
wire				lock_read_fifo_rdreq;
wire [LOCK_READ_FIFO_WIDTH-1:0] lock_read_fifo_q;
wire				lock_read_fifo_full;
wire				lock_read_fifo_wrreq;

wire [READ_COMPUTE_FIFO_WIDTH-1:0] 	read_compute_fifo_data;
wire					read_compute_fifo_empty;
wire					read_compute_fifo_rdreq;
wire [READ_COMPUTE_FIFO_WIDTH-1:0] 	read_compute_fifo_q;
wire					read_compute_fifo_full;
wire					read_compute_fifo_wrreq;

wire [COMPUTE_WRITE_FIFO_WIDTH-1:0] 	compute_write_fifo_data;
wire					compute_write_fifo_empty;
wire					compute_write_fifo_rdreq;
wire [COMPUTE_WRITE_FIFO_WIDTH-1:0] 	compute_write_fifo_q;
wire					compute_write_fifo_full;
wire					compute_write_fifo_wrreq;

wire [COMPUTE_LINK_FIFO_WIDTH-1:0] 	compute_link_fifo_data;
wire					compute_link_fifo_empty;
wire					compute_link_fifo_rdreq;
wire [COMPUTE_LINK_FIFO_WIDTH-1:0] 	compute_link_fifo_q;
wire					compute_link_fifo_full;
wire					compute_link_fifo_almost_full;
wire					compute_link_fifo_wrreq;

wire [31:0] key,tcheck_val;
wire termcheck_wren;

gen_addr #(
	.DATA_WIDTH	(DATA_WIDTH),
	.PROC_ID	(PROC_ID),
	.MAX_NUM_PROCS	(MAX_NUM_PROCS),
	.LINK_GEN_FIFO_WIDTH	(LINK_GEN_FIFO_WIDTH), 
	.GEN_LOCK_FIFO_WIDTH	(GEN_LOCK_FIFO_WIDTH),
	.UPDATE_MODE		(UPDATE_MODE),
	.ACCUM_MODE		(ACCUM_MODE)
) gen_addr (
	.clk	(clk),
	.reset	(reset),

	.log_2_num_workers_in	(log_2_num_workers_in),
	.shard_id		(shard_id),

	//input fifos
	.link_gen_fifo_q	(link_gen_fifo_q),
	.link_gen_fifo_empty	(link_gen_fifo_empty),
	.link_gen_fifo_rdreq	(link_gen_fifo_rdreq),

	.rx_ext_update_q	(rx_ext_update_q),
	.rx_ext_update_empty	(rx_ext_update_empty),
	.rx_ext_update_rdreq	(rx_ext_update_rdreq),
	.process_ext_updates	(process_ext_updates),

	//output fifo
	.gen_lock_fifo_data	(gen_lock_fifo_data),
	.gen_lock_fifo_full	(gen_lock_fifo_full),
	.gen_lock_fifo_wrreq	(gen_lock_fifo_wrreq),
	
	.compute_link_fifo_almost_full (compute_link_fifo_almost_full),

	.start_update		(start_update),
	.num_keys		(num_keys),
	.start_key_selection	(start_key_selection),
	.max_fpga_procs		(max_fpga_procs)
);

txfifo #(
        .DATA_WIDTH(GEN_LOCK_FIFO_WIDTH),
        .LOCAL_FIFO_DEPTH(4)
) gen_lock_fifo (
        .clock          (clk),
	.aclr           (reset),
        .data	        (gen_lock_fifo_data),
        .rdreq          (gen_lock_fifo_rdreq),
        .wrreq          (gen_lock_fifo_wrreq),
        .q              (gen_lock_fifo_q),
        .empty          (gen_lock_fifo_empty),
        .full           (gen_lock_fifo_full)
);


lock_key #(
	.DATA_WIDTH		(DATA_WIDTH),
	.GEN_LOCK_FIFO_WIDTH	(GEN_LOCK_FIFO_WIDTH), 
	.LOCK_READ_FIFO_WIDTH	(LOCK_READ_FIFO_WIDTH) 
) lock_key (
	.clk	(clk),
	.reset	(reset),

	.gen_lock_fifo_q	(gen_lock_fifo_q),
	.gen_lock_fifo_empty	(gen_lock_fifo_empty),
	.gen_lock_fifo_rdreq	(gen_lock_fifo_rdreq),

	.lock_read_fifo_data	(lock_read_fifo_data),
	.lock_read_fifo_full	(lock_read_fifo_full),
	.lock_read_fifo_wrreq	(lock_read_fifo_wrreq),

	.proc_key		(proc_key),
	.proc_obtain_key	(proc_obtain_key),	
	.proc_key_grant		(proc_key_grant),
	.proc_key_blocked	(proc_key_blocked),
	.locks_available	(locks_available)
);


txfifo #(
        .DATA_WIDTH(LOCK_READ_FIFO_WIDTH),
        .LOCAL_FIFO_DEPTH(4)
) lock_read_fifo (
        .clock          (clk),
	.aclr           (reset),
        .data	        (lock_read_fifo_data),
        .rdreq          (lock_read_fifo_rdreq),
        .wrreq          (lock_read_fifo_wrreq),
        .q              (lock_read_fifo_q),
        .empty          (lock_read_fifo_empty),
        .full           (lock_read_fifo_full)
);


read_filter #(
	.DDR_BASE		(DDR_BASE),
	.DEFAULT_READ_LENGTH	(DEFAULT_READ_LENGTH),
	.ADDRESS_WIDTH		(ADDRESS_WIDTH),
	.LOCK_READ_FIFO_WIDTH	(LOCK_READ_FIFO_WIDTH), 
	.READ_COMPUTE_FIFO_WIDTH(READ_COMPUTE_FIFO_WIDTH),
	.UPDATE_MODE		(UPDATE_MODE),
	.ACCUM_MODE		(ACCUM_MODE)
) read_filter (
	.clk	(clk),
	.reset	(reset),

	.lock_read_fifo_q	(lock_read_fifo_q),
	.lock_read_fifo_empty	(lock_read_fifo_empty),
	.lock_read_fifo_rdreq	(lock_read_fifo_rdreq),

	.read_compute_fifo_data	(read_compute_fifo_data),
	.read_compute_fifo_full	(read_compute_fifo_full),
	.read_compute_fifo_wrreq(read_compute_fifo_wrreq),

	//read interface b/w update unit and main memory
	.control_fixed_location		(control_fixed_location),
	.control_read_base		(control_read_base),	
	.control_read_length		(control_read_length),
	.control_go			(control_go),
	.control_done			(control_done),

	.user_read_buffer		(user_read_buffer),
	.user_buffer_data		(user_buffer_data),
	.user_data_available		(user_data_available),

	.log_2_num_workers_in		(log_2_num_workers_in),
	.filter_threshold		(filter_threshold),
	.threshold			(threshold)
);


txfifo #(
        .DATA_WIDTH(READ_COMPUTE_FIFO_WIDTH),
        .LOCAL_FIFO_DEPTH(4)
) read_compute_fifo (
        .clock          (clk),
	.aclr           (reset),
        .data	        (read_compute_fifo_data),
        .rdreq          (read_compute_fifo_rdreq),
        .wrreq          (read_compute_fifo_wrreq),
        .q              (read_compute_fifo_q),
        .empty          (read_compute_fifo_empty),
        .full           (read_compute_fifo_full)
);


compute #(
	.DATA_WIDTH(DATA_WIDTH),
	.READ_COMPUTE_FIFO_WIDTH(READ_COMPUTE_FIFO_WIDTH),
	.COMPUTE_WRITE_FIFO_WIDTH(COMPUTE_WRITE_FIFO_WIDTH),
	.COMPUTE_LINK_FIFO_WIDTH(COMPUTE_LINK_FIFO_WIDTH),
	.UPDATE_MODE(UPDATE_MODE),
	.ACCUM_MODE(ACCUM_MODE)

) compute (
	.clk	(clk),
	.reset	(reset),

	.read_compute_fifo_q		(read_compute_fifo_q),
	.read_compute_fifo_empty	(read_compute_fifo_empty),
	.read_compute_fifo_rdreq	(read_compute_fifo_rdreq),

	.compute_write_fifo_data	(compute_write_fifo_data),
	.compute_write_fifo_full	(compute_write_fifo_full),
	.compute_write_fifo_wrreq	(compute_write_fifo_wrreq),

	.compute_link_fifo_data		(compute_link_fifo_data),
	.compute_link_fifo_full		(compute_link_fifo_full),
	.compute_link_fifo_wrreq	(compute_link_fifo_wrreq),

	.key				(key),
	.tcheck_val			(tcheck_val),
	.termcheck_wren			(termcheck_wren),
	.filter_threshold		(filter_threshold),
	.algo_selection			(algo_selection)
	
);


txfifo #(
        .DATA_WIDTH(COMPUTE_WRITE_FIFO_WIDTH),
        .LOCAL_FIFO_DEPTH(4)
) compute_write_fifo (
        .clock          (clk),
	.aclr           (reset),
        .data	        (compute_write_fifo_data),
        .rdreq          (compute_write_fifo_rdreq),
        .wrreq          (compute_write_fifo_wrreq),
        .q              (compute_write_fifo_q),
        .empty          (compute_write_fifo_empty),
        .full           (compute_write_fifo_full)
);

txfifo #(
        .DATA_WIDTH(COMPUTE_LINK_FIFO_WIDTH),
        .LOCAL_FIFO_DEPTH(32)
) compute_link_fifo (
        .clock          (clk),
	.aclr           (reset),
        .data	        (compute_link_fifo_data),
        .rdreq          (compute_link_fifo_rdreq),
        .wrreq          (compute_link_fifo_wrreq),
        .q              (compute_link_fifo_q),
        .empty          (compute_link_fifo_empty),
        .full           (compute_link_fifo_full),
        .almost_full    (compute_link_fifo_almost_full)
);


link_read #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.DDR_BASE(DDR_BASE),
	.DEFAULT_READ_LENGTH(DEFAULT_READ_LENGTH),
	.COMPUTE_LINK_FIFO_WIDTH(COMPUTE_LINK_FIFO_WIDTH),
	.LINK_GEN_FIFO_WIDTH(LINK_GEN_FIFO_WIDTH)
) link_read (
	.clk	(clk),
	.reset	(reset),

	.compute_link_fifo_q	(compute_link_fifo_q),
	.compute_link_fifo_empty(compute_link_fifo_empty),
	.compute_link_fifo_rdreq(compute_link_fifo_rdreq),

	.link_gen_fifo_data	(link_gen_fifo_data),
	.link_gen_fifo_full	(link_gen_fifo_full),
	.link_gen_fifo_wrreq	(link_gen_fifo_wrreq),

	.log_2_num_workers_in	(log_2_num_workers_in),
	.shard_id		(shard_id),

	//read interface b/w link reader and main memory
	.link_control_fixed_location	(link_control_fixed_location),
	.link_control_read_base		(link_control_read_base),	
	.link_control_read_length	(link_control_read_length),
	.link_control_go		(link_control_go),
	.link_control_done		(link_control_done),

	.link_user_read_buffer		(link_user_read_buffer),
	.link_user_buffer_data		(link_user_buffer_data),
	.link_user_data_available	(link_user_data_available),

	//external fifo 
	.ext_fifo_data		(ext_fifo_data),
	.ext_fifo_wrreq		(ext_fifo_wrreq),
	.ext_fifo_full		(ext_fifo_full),
	.threshold		(threshold)
);


txfifo #(
        .DATA_WIDTH(LINK_GEN_FIFO_WIDTH),
        .LOCAL_FIFO_DEPTH(64)
) link_gen_fifo (
        .clock          (clk),
	.aclr           (reset),
        .data	        (link_gen_fifo_data),
        .rdreq          (link_gen_fifo_rdreq),
        .wrreq          (link_gen_fifo_wrreq),
        .q              (link_gen_fifo_q),
        .empty          (link_gen_fifo_empty),
        .full           (link_gen_fifo_full)
);


write_release #(
	.DDR_BASE(DDR_BASE),
	.DEFAULT_READ_LENGTH(DEFAULT_READ_LENGTH),
	.COMPUTE_WRITE_FIFO_WIDTH(COMPUTE_WRITE_FIFO_WIDTH)
) write_release (
	.clk	(clk),
	.reset	(reset),

	.compute_write_fifo_q		(compute_write_fifo_q),
	.compute_write_fifo_empty	(compute_write_fifo_empty),
	.compute_write_fifo_rdreq	(compute_write_fifo_rdreq),

	.wr_control_fixed_location	(wr_control_fixed_location),
	.wr_control_write_base		(wr_control_write_base),
	.wr_control_write_length	(wr_control_write_length),
        .wr_control_go			(wr_control_go),
        .wr_control_done		(wr_control_done),
	
	.wr_user_write_buffer		(wr_user_write_buffer),
	.wr_user_buffer_data		(wr_user_buffer_data), 
	.wr_user_buffer_full		(wr_user_buffer_full),

	.log_2_num_workers_in		(log_2_num_workers_in),
		
	.proc_key_release		(proc_key_release),
	.proc_key_release_ack		(proc_key_release_ack)
);



///////////////////////////////////////

wire [63:0] iteration_accum_buffer_dataout;
txfifo #(
        .DATA_WIDTH(64),
        //.LOCAL_FIFO_DEPTH(256)
        .LOCAL_FIFO_DEPTH(16)
) iteration_accum_buffer (
        .aclr           (reset),
        //.data           ({lfsr_address_out,topk_user_buffer_output_data[63:32]}), //This FIFO stores the value field, which is used for termination checks)
        .data           ({key,tcheck_val}), //This FIFO stores the value field, which is used for termination checks)
        .clock          (clk),
        .rdreq          (iteration_accum_buffer_rdreq),
        .wrreq          (termcheck_wren&!iteration_accum_buffer_full),
        .q              (iteration_accum_buffer_dataout),
        .empty          (iteration_accum_buffer_empty),
        .full           (iteration_accum_buffer_full),
        .usedw          ()
);


term_check_pr #(
	.PROC_ID(PROC_ID)
)tcheck (
	.clk	(clk),
	.reset	(reset),
	.num_keys(num_keys),

	//iteration accumulation
	.iteration_accum_buffer_rdreq	(iteration_accum_buffer_rdreq),
	.iteration_accum_buffer_dataout	(iteration_accum_buffer_dataout),
	.iteration_accum_buffer_empty	(iteration_accum_buffer_empty),

	.accum_value			(iteration_accum_value),
	.log_2_num_workers_in		(log_2_num_workers_in)
	//.start_update			(start_update)
);

endmodule


