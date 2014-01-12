`timescale 1ns/1ps

//`define MAXVAL

module compute #(
	parameter DATA_WIDTH=32,
	parameter READ_COMPUTE_FIFO_WIDTH=290, //(1+1+32+256)
	parameter COMPUTE_WRITE_FIFO_WIDTH=257,
	parameter COMPUTE_LINK_FIFO_WIDTH=96,
	parameter UPDATE_MODE=0,
	parameter ACCUM_MODE=1
) (
	input clk,
	input reset,
	
	input [READ_COMPUTE_FIFO_WIDTH-1:0] 		read_compute_fifo_q,
	input 						read_compute_fifo_empty,
	output reg					read_compute_fifo_rdreq,

	output reg [COMPUTE_WRITE_FIFO_WIDTH-1:0] 	compute_write_fifo_data,
	input 						compute_write_fifo_full,
	output reg					compute_write_fifo_wrreq,

	output reg [COMPUTE_LINK_FIFO_WIDTH-1:0] 	compute_link_fifo_data,
	input 						compute_link_fifo_full,
	output reg					compute_link_fifo_wrreq,

	//interface b/w update unit and termcheck
	output reg [31:0] 				key,
	output wire [31:0] 				tcheck_val,
	output reg        				termcheck_wren,
	input [31:0]					filter_threshold,
	input						algo_selection
);




//log2
function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
endfunction // log2

localparam NUM_STATES		=9;
localparam IDLE			=0;
localparam READ_FIFO		=1;
localparam PARSE_FIELDS		=2;
localparam FILTER		=3;
localparam WAIT_TIMEOUT		=4;
localparam ACCUM_WRITE		=5;
localparam UPDATE_WRITE		=6;
localparam LINK_WRITE		=7;
localparam FILTER_WRITE		=8;

localparam MAXVAL_WAIT_CYCLES=1;
localparam PR_KATZ_WAIT_CYCLES=7;
localparam COMPUTE_WAIT_CYCLES=PR_KATZ_WAIT_CYCLES;
//registers and wires
reg [log2(NUM_STATES)-1:0]	state, state_next;
reg mod_bit, mod_bit_next;
reg [DATA_WIDTH-1:0] 			val, delta_val,pri,data_ptr,data_size, mult_factor, self_links;
reg [DATA_WIDTH-1:0] 			key_next, val_next, delta_val_next, pri_next, data_ptr_next, data_size_next, mult_factor_next, self_links_next;
//separate field values
reg termcheck_wren_next;


reg [log2(COMPUTE_WAIT_CYCLES)-1:0] 	timeout;
reg start_timeout, start_timeout_next;
wire timeout_expired;



reg compute_write_fifo_wrreq_next;
reg [31:0] msg, msg_next;
reg filter_bit, filter_bit_next;

reg read_compute_fifo_rdreq_next;
reg [COMPUTE_WRITE_FIFO_WIDTH-1:0] compute_write_fifo_data_next;
reg [COMPUTE_LINK_FIFO_WIDTH-1:0] compute_link_fifo_data_next;
reg compute_link_fifo_wrreq_next;


wire [31:0] val_op_delta_val;
wire [31:0] val_plus_delta_val;
wire [31:0] val_gt_delta_val;

assign tcheck_val = val; //val_plus_delta_val;

//accumulate operation
assign val_op_delta_val = (algo_selection==0)?val_plus_delta_val:val_gt_delta_val;
assign val_gt_delta_val=(val>delta_val)?val:delta_val; //enable for maxval
float_add_sub float_add_sub(
        .clock  	(clk),
        .clk_en 	(1'b1),
        .dataa  	(val),
        .datab  	(delta_val),
        .overflow	(overflow),
        .result 	(val_plus_delta_val)
);

//calculate g(delta_val)
wire [31:0] g_update;
wire [31:0] g_update_maxval;
wire [31:0] g_update_pr_katz;

assign g_update = (algo_selection==0)?g_update_pr_katz:g_update_maxval;
assign g_update_maxval = val;
float_mult float_mult_inst (
        .clock 		(clk),
        .dataa 		(delta_val),
        .datab 		(mult_factor),
        .overflow 	(overflow_mult),
        .result 	(g_update_pr_katz)
        );

wire [31:0] accumulated_delta_val;
wire [31:0] accumulated_delta_val_pr_katz;
wire [31:0] accumulated_delta_val_maxval;


assign accumulated_delta_val = (algo_selection==0)?accumulated_delta_val_pr_katz:accumulated_delta_val_maxval;
assign accumulated_delta_val_maxval = (delta_val>msg)?delta_val:msg;
float_add_sub float_accum_add_sub(
        .clock  (clk),
        .clk_en (1'b1),
        .dataa  (msg),
        //.datab  (g_update),
        .datab  (delta_val),
        .overflow(overflow),
        .result (accumulated_delta_val_pr_katz)
);


/*A comparator for floating point comparisons*/
/*
wire g_update_greater_than_filter_threshold;
float_cmp comp_inst (
        .clk_en         (1'b1),
        .clock          (clk),
        .dataa          (g_update), //delta_val
        .datab          (filter_threshold),
        .ageb           (g_update_greater_than_filter_threshold)
);
*/


always@(*)
begin

	state_next = state;
	start_timeout_next = 0;
	read_compute_fifo_rdreq_next = 0;
	compute_write_fifo_wrreq_next = 0;
	compute_write_fifo_data_next = compute_write_fifo_data;
	compute_link_fifo_wrreq_next = 0;
	compute_link_fifo_data_next = compute_link_fifo_data;

	key_next	        = key;
	val_next             	= val;
	delta_val_next       	= delta_val;
	pri_next             	= pri;
	data_ptr_next        	= data_ptr; 
	data_size_next       	= data_size;
	mult_factor_next     	= mult_factor;
	self_links_next      	= self_links;
	msg_next		= msg;
 	filter_bit_next 	= filter_bit;
	mod_bit_next 		= mod_bit;

	termcheck_wren_next	= 0;

	case(state)
		IDLE: begin
			if(!read_compute_fifo_empty) begin
				read_compute_fifo_rdreq_next = 1'b1;
				state_next = READ_FIFO;
			end			
		end

		READ_FIFO: begin
			state_next = PARSE_FIELDS;
		end

		PARSE_FIELDS:begin
			key_next	     = read_compute_fifo_q[31:0];
			val_next             = read_compute_fifo_q[63:32];
			delta_val_next       = read_compute_fifo_q[95:64];
			pri_next             = read_compute_fifo_q[127:96];
			data_ptr_next        = read_compute_fifo_q[159:128]; 
			data_size_next       = read_compute_fifo_q[191:160];
			mult_factor_next     = read_compute_fifo_q[223:192];
			self_links_next      = read_compute_fifo_q[255:224];
			msg_next	     = read_compute_fifo_q[287:256];
 			filter_bit_next      = read_compute_fifo_q[288:288];
			mod_bit_next 	     = read_compute_fifo_q[289:289];
			state_next	     = FILTER;
		end		

		FILTER: begin //bypass the stage if filter bit set
			if(mod_bit==ACCUM_MODE) begin
				state_next = WAIT_TIMEOUT;
				start_timeout_next = 1'b1;
			end
			else begin
				termcheck_wren_next = 1'b1;
				if(filter_bit) begin
					state_next = FILTER_WRITE;
				end
				else begin
					state_next = WAIT_TIMEOUT;
					start_timeout_next = 1'b1;
				end
			end
		end

		WAIT_TIMEOUT: begin
			if(timeout_expired) begin
				state_next = (mod_bit==UPDATE_MODE)?UPDATE_WRITE:ACCUM_WRITE;
			end
		end

		ACCUM_WRITE:begin
			if(!compute_write_fifo_full) begin
				compute_write_fifo_wrreq_next = 1'b1;
				state_next = IDLE;
				//Filter bit must be 0 for accumulate writes
				//(we must not ignore accum values even if
				//they are less than the threshold
				compute_write_fifo_data_next = {1'b0,self_links,mult_factor,data_size,data_ptr,pri,accumulated_delta_val,val,key}; 
			end
		end


		UPDATE_WRITE:begin
			if(!compute_write_fifo_full) begin
				compute_write_fifo_wrreq_next = 1'b1;
				//state_next = IDLE;
				state_next = LINK_WRITE; //deepak debug
				////enable to cut the feedback path
				//compute_write_fifo_data_next = {filter_bit,self_links,mult_factor,data_size,data_ptr,pri,32'h0,val_plus_delta_val,key};
				compute_write_fifo_data_next = {filter_bit,self_links,mult_factor,data_size,data_ptr,pri,32'h0,val_op_delta_val,key};


			end
		end

		LINK_WRITE:begin
			if(!compute_link_fifo_full) begin
				compute_link_fifo_data_next = {data_ptr,data_size,g_update};
				compute_link_fifo_wrreq_next = 1'b1;
				state_next = IDLE;
			end
		end

		FILTER_WRITE:begin
			if(!compute_write_fifo_full) begin
				compute_write_fifo_wrreq_next = 1'b1;
				state_next = IDLE;
				compute_write_fifo_data_next = {filter_bit,self_links,mult_factor,data_size,data_ptr,pri,delta_val,val,key}; 
			end
		end
				
		default: state_next = IDLE;
	endcase
end



assign timeout_expired = (timeout==0)&(start_timeout==0);
always@(posedge clk) 
begin
	if(reset) begin
		timeout <= 0;	
	end 
	else begin
		if(start_timeout) begin
			timeout <= (algo_selection==0)?PR_KATZ_WAIT_CYCLES:MAXVAL_WAIT_CYCLES;
		end
		else if(timeout_expired) begin
			timeout <= 0;
		end
		else begin
			timeout <= timeout-1;
		end
	end
end


always@(posedge clk) begin
	if(reset) begin
		state 				<= IDLE;
		start_timeout 			<= 0;
		read_compute_fifo_rdreq 	<= 0;
		compute_write_fifo_wrreq 	<= 0;
		compute_write_fifo_data 	<= 0;
		compute_link_fifo_wrreq 	<= 0;
		compute_link_fifo_data 		<= 0;

		key 			<= 0;
		val 			<= 0;
		delta_val 		<= 0;
		pri 			<= 0;
		data_ptr 		<= 0; 
		data_size 		<= 0;
		mult_factor 		<= 0;
		self_links 		<= 0;
		msg 			<= 0;
	 	filter_bit 		<= 0;
		mod_bit 		<= 0;
		termcheck_wren		<= 0;
	end
	else begin
		state 				<= state_next;
		start_timeout 			<= start_timeout_next;
		read_compute_fifo_rdreq 	<= read_compute_fifo_rdreq_next;
		compute_write_fifo_wrreq 	<= compute_write_fifo_wrreq_next;
		compute_write_fifo_data 	<= compute_write_fifo_data_next;
		compute_link_fifo_wrreq 	<= compute_link_fifo_wrreq_next;
		compute_link_fifo_data 	<= compute_link_fifo_data_next;

		key	        <= key_next;
		val             <= val_next;
		delta_val       <= delta_val_next;
		pri             <= pri_next;
		data_ptr        <= data_ptr_next; 
		data_size       <= data_size_next;
		mult_factor     <= mult_factor_next;
		self_links      <= self_links_next;
		msg		<= msg_next;
	 	filter_bit 	<= filter_bit_next;
		mod_bit 	<= mod_bit_next;
		termcheck_wren	<= termcheck_wren_next;
	end
end
endmodule
