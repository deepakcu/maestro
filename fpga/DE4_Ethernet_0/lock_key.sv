//written by lgk

`timescale 1ns/1ps

module lock_key #(
	parameter DATA_WIDTH=32,
	parameter GEN_LOCK_FIFO_WIDTH=65,
	parameter LOCK_READ_FIFO_WIDTH=65
) (
	input clk,
	input reset,

	input [GEN_LOCK_FIFO_WIDTH-1:0] 	gen_lock_fifo_q,
	input 					gen_lock_fifo_empty,
	output reg				gen_lock_fifo_rdreq,

	output reg [LOCK_READ_FIFO_WIDTH-1:0] 	lock_read_fifo_data,
	input 					lock_read_fifo_full,
	output reg				lock_read_fifo_wrreq,

	output reg [31:0] 			proc_key,
	output reg				proc_obtain_key,
	input 					proc_key_grant,
	input 					proc_key_blocked,
	input					locks_available
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

localparam WAIT_CYCLES		=20; //retry bus lock after 20 cycles
localparam NUM_STATES		=6;
localparam IDLE			=0;
localparam READ_FIFO		=1;
localparam PARSE_ENTRIES	=2;
localparam WAIT_ACQ_KEY		=3;
localparam WRITE_FIFO		=4;
localparam WAIT_RETRY		=5;

//registers and wires
reg [log2(NUM_STATES)-1:0]	state, state_next;

reg				gen_lock_fifo_rdreq_next;
reg [LOCK_READ_FIFO_WIDTH-1:0] 	lock_read_fifo_data_next;
reg				lock_read_fifo_wrreq_next;

reg [DATA_WIDTH-1:0] proc_key_next;
reg proc_obtain_key_next;
reg [LOCK_READ_FIFO_WIDTH-1:0] 	entry, entry_next;
reg [log2(WAIT_CYCLES)-1:0] 	timeout;
reg start_timeout, start_timeout_next;
wire timeout_expired;

assign timeout_expired = (timeout==0)&(start_timeout==0);

always@(*)
begin

	state_next = state;
	proc_key_next = proc_key;
	proc_obtain_key_next = proc_obtain_key;
	lock_read_fifo_data_next = lock_read_fifo_data;
	lock_read_fifo_wrreq_next = 0;
	gen_lock_fifo_rdreq_next = 0;
	entry_next = entry;
	start_timeout_next = 0;

	case(state)
		IDLE: begin
			if((!gen_lock_fifo_empty)&locks_available) begin
				gen_lock_fifo_rdreq_next = 1;
				state_next = READ_FIFO;
			end
		end

		READ_FIFO: begin
			state_next = PARSE_ENTRIES;
		end
	
		PARSE_ENTRIES:begin
			entry_next 		= gen_lock_fifo_q;
			proc_key_next 		= gen_lock_fifo_q[63:32]; //place key to lock
			proc_obtain_key_next 	= 1;			
			state_next 		= WAIT_ACQ_KEY;
		end

		WAIT_ACQ_KEY: begin
			if(proc_key_grant) begin
				proc_obtain_key_next 	= 0;
				state_next 		= WRITE_FIFO;
			end
			else if(proc_key_blocked) begin
				proc_obtain_key_next	= 0;
				start_timeout_next 	= 1'b1;
				state_next		= WAIT_RETRY;
			end
			else begin
				state_next 		= WAIT_ACQ_KEY;
			end
		end

		WRITE_FIFO: begin
			if(!lock_read_fifo_full) begin
				lock_read_fifo_wrreq_next = 1;
				lock_read_fifo_data_next  = entry;	
				state_next = IDLE;
			end
		end

		WAIT_RETRY:begin
			if(timeout_expired) begin	
				proc_obtain_key_next = 1;
				state_next = WAIT_ACQ_KEY;
			end 
		end

	endcase
end


always@(posedge clk) 
begin
	if(reset) begin
		timeout <= 0;	
	end 
	else begin
		if(start_timeout) begin
			timeout <= WAIT_CYCLES;
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
		proc_key			<= 0;
		proc_obtain_key			<= 0;
		lock_read_fifo_data		<= 0;
		lock_read_fifo_wrreq		<= 0;
		gen_lock_fifo_rdreq		<= 0;
		entry				<= 0;
		start_timeout			<= 0;
	end
	else begin
		state 				<= state_next;
		proc_key			<= proc_key_next;
		proc_obtain_key			<= proc_obtain_key_next;
		lock_read_fifo_data		<= lock_read_fifo_data_next;
		lock_read_fifo_wrreq		<= lock_read_fifo_wrreq_next;
		gen_lock_fifo_rdreq		<= gen_lock_fifo_rdreq_next;
		entry				<= entry_next;
		start_timeout			<= start_timeout_next;
	end
end
endmodule
