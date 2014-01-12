//written by lgk

`timescale 1ns/1ps

module read_filter #(
	parameter DDR_BASE=0,
	parameter DEFAULT_READ_LENGTH=256,
        parameter ADDRESS_WIDTH = 31,
	parameter DATA_WIDTH=32,
	parameter LOCK_READ_FIFO_WIDTH=(64+1), //key+msg+mod bit
	parameter READ_COMPUTE_FIFO_WIDTH=(1+1+32+256), //mod bit+filter bit+msg+key record
	parameter UPDATE_MODE=0,
	parameter ACCUM_MODE=1
) (
	input clk,
	input reset,

	//interface btwn read-filter unit and input fifo
	input [LOCK_READ_FIFO_WIDTH-1:0] 	lock_read_fifo_q,
	input 					lock_read_fifo_empty,
	output reg				lock_read_fifo_rdreq,

	//interface btwn read-filter unit and output fifo
	output reg[READ_COMPUTE_FIFO_WIDTH-1:0] read_compute_fifo_data,
	input 					read_compute_fifo_full,
	output reg				read_compute_fifo_wrreq,

	//interface btwn read-filter unit and main memory
	output reg 				user_read_buffer,
	input wire 				user_data_available,
	input [255:0] 				user_buffer_data,
	
	output wire			      	control_fixed_location,
	output reg [ADDRESS_WIDTH-1:0]        	control_read_base,	
	output reg                             	control_go,
	output reg [ADDRESS_WIDTH-1:0]         	control_read_length,
	input wire 			       	control_done,

	input [31:0] 				log_2_num_workers_in,
	input [31:0]				threshold,
	input [31:0]				filter_threshold

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

assign control_fixed_location = 0;

localparam NUM_STATES		=7;
localparam IDLE			=0;
localparam READ_FIFO		=1;
localparam PLACE_READ		=2;
localparam WAIT_READ		=3;
localparam RECORD_PROC		=4;
localparam COMPARE_KEY		=5;
localparam WRITE_FIFO		=6;

//registers and wires
reg [log2(NUM_STATES)-1:0]	state, state_next;

reg					lock_read_fifo_rdreq_next;
reg [READ_COMPUTE_FIFO_WIDTH-1:0] 	read_compute_fifo_data_next;
reg					read_compute_fifo_wrreq_next;

reg [ADDRESS_WIDTH-1:0]         control_read_base_next;	
reg [ADDRESS_WIDTH-1:0]         control_read_length_next;
reg                             control_go_next;

reg [255:0] 	key_record,key_record_next;
reg 		mod_bit, mod_bit_next;
reg [31:0] 	msg, msg_next;
reg 		user_read_buffer_next;

wire delta_val_greater_than_threshold;
wire delta_val_greater_than_filter_threshold;






always@(*)
begin

	state_next = state;
	read_compute_fifo_data_next = read_compute_fifo_data;
	read_compute_fifo_wrreq_next = 0;
	lock_read_fifo_rdreq_next = 0;

	user_read_buffer_next = 0;
        control_go_next = 0;
	control_read_base_next = control_read_base;
        control_read_length_next = control_read_length;

	key_record_next = key_record;
	mod_bit_next	= mod_bit;
	msg_next	= msg;	

	case(state)
		IDLE: begin
			if(!lock_read_fifo_empty) begin
				lock_read_fifo_rdreq_next = 1;
				state_next = READ_FIFO;
			end
		end

		READ_FIFO: begin
			state_next = PLACE_READ;
		end

		PLACE_READ: begin
			mod_bit_next			= lock_read_fifo_q[64];
			msg_next			= lock_read_fifo_q[31:0];
			//ddr addr = hash(key)*32. Hash fn = mod
			control_read_base_next 		= DDR_BASE+((lock_read_fifo_q[63:32]>>log_2_num_workers_in)<<5); 
                        control_read_length_next 	= DEFAULT_READ_LENGTH;
                        control_go_next 		= 1'b1;
			state_next 			= WAIT_READ;
		end

		WAIT_READ: begin
			if(user_data_available) begin
                                user_read_buffer_next 	= 1'b1;
                                state_next 		= RECORD_PROC;
                        end
		end						

		RECORD_PROC: begin
			key_record_next	      = user_buffer_data;
			state_next 	      = COMPARE_KEY;
		end

		COMPARE_KEY: begin
			state_next = WRITE_FIFO;
		end

		WRITE_FIFO: begin
			if(!read_compute_fifo_full) begin
				
				state_next = IDLE;
				read_compute_fifo_wrreq_next = 1;
					
				//Note: for katz, sw must set filter threshold
				//to 0 to enough accumulate keys during start
				if(delta_val_greater_than_threshold & delta_val_greater_than_filter_threshold) begin //comment for katz
				//deepak comment below for katz fix
				//if(delta_val_greater_than_threshold & delta_val_greater_than_filter_threshold) begin
					read_compute_fifo_data_next = {mod_bit,1'b0,msg,key_record}; //set filter bit to 0 (dont filter)
				end
				else begin
					read_compute_fifo_data_next = {mod_bit,1'b1,msg,key_record}; //set filter bit to 1
				end
			end
		end

	endcase
end

always@(posedge clk) begin
	if(reset) begin
		state 				<= IDLE;
		read_compute_fifo_data		<= 0;
		read_compute_fifo_wrreq		<= 0;
		lock_read_fifo_rdreq		<= 0;
		user_read_buffer 		<= 0;
        	control_go 			<= 0;
        	control_read_base 		<= 0;
	        control_read_length 		<= 0;
		key_record			<= 0;
		mod_bit				<= 0;
		msg				<= 0;	
	end
	else begin
		state 				<= state_next;
        	control_go 			<= control_go_next;
        	control_read_length 		<= control_read_length_next;
		user_read_buffer 		<= user_read_buffer_next;
		read_compute_fifo_data		<= read_compute_fifo_data_next;
		read_compute_fifo_wrreq		<= read_compute_fifo_wrreq_next;
		lock_read_fifo_rdreq		<= lock_read_fifo_rdreq_next;
 		control_read_base 		<= control_read_base_next;
		key_record			<= key_record_next;
		mod_bit				<= mod_bit_next;
		msg				<= msg_next;	
	end
end


/*A comparator for floating point comparisons*/
float_cmp fcomp (
        .clk_en         (1'b1),
        .clock          (clk),
        .dataa          (key_record[95:64]), //delta_val
	.datab          (threshold),
//        .datab		(32'h0),
        .ageb           (delta_val_greater_than_threshold)
);


/*A comparator for floating point comparisons*/
float_cmp comp_inst (
        .clk_en         (1'b1),
        .clock          (clk),
        .dataa          (key_record[95:64]), //delta_val
        .datab          (filter_threshold),
        .ageb           (delta_val_greater_than_filter_threshold)
);


endmodule
