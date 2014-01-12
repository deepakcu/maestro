

module processor #(
	parameter DEFAULT_READ_LENGTH = 32,
        parameter DATA_WIDTH = 32,
        parameter DDR_BASE = 0, 
        parameter DDR_SIZE = 1073741824, //1Gb
        parameter ADDRESS_WIDTH = 31,
	parameter MAX_NUM_PROCS = 2,
	parameter PROC_ID = 0,
	parameter MAX_LOCK_KEYS = 4,
	parameter EXT_PROCESSOR=0

) (
	input 		clk,
	input 		reset,

	//write interface b/w update unit and main memory
	output wire 		wr_control_fixed_location,
	output wire [30:0] 	wr_control_write_base,
	output wire [30:0] 	wr_control_write_length,
	output wire 		wr_control_go,
	input wire 		wr_control_done,

	output wire 		wr_user_write_buffer,
	output wire [255:0] 	wr_user_buffer_data,
	input wire 		wr_user_buffer_full,

	//read interface b/w update unit and main memory
	output wire		control_fixed_location,
	output wire [30:0] 	control_read_base,
	output wire [30:0] 	control_read_length,
	output wire 		control_go,
	input wire		control_done,

	output wire 		user_read_buffer,
	input wire [255:0] 	user_buffer_data,
	input wire		user_data_available,

	//read interface b/w update unit and main memory
	output wire		link_control_fixed_location,
	output wire [30:0] 	link_control_read_base,
	output wire [30:0] 	link_control_read_length,
	output wire 		link_control_go,
	input wire		link_control_done,

	output wire 		link_user_read_buffer,
	input wire [255:0] 	link_user_buffer_data,
	input wire		link_user_data_available,


	//interfaces b/w cache controller and snoopy bus
	output [31:0] 		snoopy_bus_key_to_be_locked,
	output wire		snoopy_bus_request,
	input wire		snoopy_bus_grant,
	output wire		snoopy_bus_release,
	output wire		snoop_check_req,
	input wire		add_conflict_snoopy_to_proc,
	
	//interface b/w snooper and snoopy bus
	input wire		snoop_check,
	input wire [31:0]	snoop_bus,
	output wire		add_conflict_proc_to_snoopy,

	//interface b/w update unit and top k selection circuit
	input wire 		start_key_process,
        output wire		start_key_selection,

	//misc status signals to update unit
	input wire [31:0]       filter_threshold,
	input wire [31:0]	threshold,
	input wire [31:0]    	log_2_num_workers_in,
	input wire [31:0] 	num_keys,
	input [31:0]		shard_id,
	input [3:0]    		max_fpga_procs,
	input	       		algo_selection,
	//external fifo 
	output [63:0] 		ext_fifo_data,
	output        		ext_fifo_wrreq,
	input         		ext_fifo_full,
	input			process_ext_updates,
	
	//rx fifo
	input [63:0]		rx_ext_update_q,
	output 			rx_ext_update_rdreq,
	input			rx_ext_update_empty,

	output wire [31:0] 	iteration_accum_value,
	input wire 		start_update
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

//interface b/w processor and cache controller
wire [31:0] proc_key;
wire proc_obtain_key;
wire proc_key_grant;
wire proc_key_release;
wire proc_key_release_ack;

//interface b/w snooper and cache controller
wire [31:0] locked_key[MAX_LOCK_KEYS-1:0];


snooper #(
	.MAX_LOCK_KEYS(MAX_LOCK_KEYS)
) snooper (
	.clk		(clk),
	.reset		(reset),

	//interface b/w snooper and snoopy bus
	.snoop_check	(snoop_check),
	.snoop_bus	(snoop_bus),
	.add_conflict	(add_conflict_proc_to_snoopy),

	//interface b/w snooper and cache controller
	.locked_key	(locked_key)
//	.match_lines		(match_lines)
);


coherence_controller #(
	.MAX_LOCK_KEYS(MAX_LOCK_KEYS)
) coherence_ctrl (
	.clk		(clk),
	.reset		(reset),

	//interface b/w snoopy bus and cache controller
	.snoopy_bus_key_to_be_locked	(snoopy_bus_key_to_be_locked),
	.snoopy_bus_request		(snoopy_bus_request),
	.snoopy_bus_grant		(snoopy_bus_grant),
	.snoopy_bus_release		(snoopy_bus_release),
	.snoop_check_req		(snoop_check_req),
	.add_conflict_snoopy_to_proc	(add_conflict_snoopy_to_proc),

	//interface b/w processor and cache controller
	.proc_key	 		(proc_key),
	.proc_obtain_key 		(proc_obtain_key),
	.proc_key_grant	 		(proc_key_grant),
	.proc_key_blocked		(proc_key_blocked),
	.proc_key_release 		(proc_key_release),
	.proc_key_release_ack 		(proc_key_release_ack),
	.locks_available		(locks_available),
	
	//interface b/w snooper and snoopy bus
	.locked_key_export		(locked_key)
);

pipeline #(

	.DEFAULT_READ_LENGTH(DEFAULT_READ_LENGTH),
        .DATA_WIDTH(DATA_WIDTH),
	.DDR_BASE(DDR_BASE), 
        .DDR_SIZE(DDR_SIZE), //1Gb
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
	.MAX_NUM_PROCS(MAX_NUM_PROCS),	
	.PROC_ID(PROC_ID),
	.EXT_PROCESSOR(EXT_PROCESSOR)
) pipeline (
	.clk		(clk),
	.reset		(reset),

	//write interface b/w update unit and main memory
	.wr_control_fixed_location	(wr_control_fixed_location),
	.wr_control_write_base		(wr_control_write_base),
	.wr_control_write_length	(wr_control_write_length),
        .wr_control_go			(wr_control_go),
        .wr_control_done		(wr_control_done),
	
	.wr_user_write_buffer		(wr_user_write_buffer),
	.wr_user_buffer_data		(wr_user_buffer_data), 
	.wr_user_buffer_full		(wr_user_buffer_full),

	//read interface b/w update unit and main memory
	.control_fixed_location		(control_fixed_location),
	.control_read_base		(control_read_base),	
	.control_read_length		(control_read_length),
	.control_go			(control_go),
	.control_done			(control_done),

	.user_read_buffer		(user_read_buffer),
	.user_buffer_data		(user_buffer_data),
	.user_data_available		(user_data_available),

	//read interface b/w link reader and main memory
	.link_control_fixed_location	(link_control_fixed_location),
	.link_control_read_base		(link_control_read_base),	
	.link_control_read_length	(link_control_read_length),
	.link_control_go		(link_control_go),
	.link_control_done		(link_control_done),

	.link_user_read_buffer		(link_user_read_buffer),
	.link_user_buffer_data		(link_user_buffer_data),
	.link_user_data_available	(link_user_data_available),


	//interface b/w update unit and cache controller
	.proc_key	 		(proc_key),
	.proc_obtain_key 		(proc_obtain_key),
	.proc_key_grant	 		(proc_key_grant),
	.proc_key_blocked		(proc_key_blocked),
	.proc_key_release 		(proc_key_release),
	.proc_key_release_ack 		(proc_key_release_ack),
	.locks_available		(locks_available),

	//misc status signals to update unit
	.filter_threshold	(filter_threshold),
	.threshold		(threshold), 
	.log_2_num_workers_in	(log_2_num_workers_in),
	.num_keys		(num_keys),
	.shard_id		(shard_id),
	.max_fpga_procs			(max_fpga_procs),
	.algo_selection			(algo_selection),

	//external fifo 
	.ext_fifo_data		(ext_fifo_data),
	.ext_fifo_wrreq		(ext_fifo_wrreq),
	.ext_fifo_full		(ext_fifo_full),
	.process_ext_updates	(process_ext_updates),
	
	//rx fifo
	.rx_ext_update_q	(rx_ext_update_q),
	.rx_ext_update_rdreq	(rx_ext_update_rdreq),
	.rx_ext_update_empty	(rx_ext_update_empty),
	
	//interface b/w update unit and top k selection circuit
	.start_key_process	(start_key_process),
        .start_key_selection	(start_key_selection),

	.iteration_accum_value	(iteration_accum_value),
	.start_update		(start_update)

);



endmodule
