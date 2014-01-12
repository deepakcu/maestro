`timescale 1ns/1ps

/*

Requester must assert snoopy_bus_request line with address placed in snoopy_bus_key_to_be_locked
It must keep asserting until snoopy_bus_grant signal goes high.

The snoopy bus arbiter must first prioritize the requests. Then, it must assert the 
bus grant signal and place the snoopy_bus_key_to_be_locked on the bus. It must hold this signal 
until the requester asserts the release signal.

*/

module snoopy_bus_arbiter #(
	parameter MAX_NUM_PROCS=2

) (
	input clk,
	input reset,

	//requests to access bus 
	input	     snoopy_bus_request[MAX_NUM_PROCS-1:0], 
	output       snoopy_bus_grant[MAX_NUM_PROCS-1:0],
	input	     snoopy_bus_release[MAX_NUM_PROCS-1:0],

	output reg [log2(MAX_NUM_PROCS)-1:0]	winner,
	input [3:0]	max_fpga_procs

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

localparam EXT_PROC_NUM=MAX_NUM_PROCS;

reg [log2(MAX_NUM_PROCS)-1:0] 	sel_encoded;
wire [MAX_NUM_PROCS-1:0] 		bus_request_internal;
reg [log2(MAX_NUM_PROCS)-1:0]	winner_next;
reg [MAX_NUM_PROCS-1:0] snoopy_bus_grant_internal, snoopy_bus_grant_internal_next;
reg state, state_next;

reg [log2(MAX_NUM_PROCS)-1:0] rr_counter, rr_counter_next; //round robin counter

localparam IDLE=0;
localparam GRANT=1;

genvar i;
generate
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin:translate
	assign snoopy_bus_grant[i] = snoopy_bus_grant_internal[i];
	assign bus_request_internal[i] = snoopy_bus_request[i];
end
endgenerate




always@(*)
begin
	state_next 	= state;
	snoopy_bus_grant_internal_next  = snoopy_bus_grant_internal;
	winner_next	= winner;
	rr_counter_next = rr_counter;

	case(state)
		IDLE: begin
			if(bus_request_internal[rr_counter]==0) begin
				/*
				if(rr_counter==(max_fpga_procs-1)) begin
					rr_counter_next = MAX_NUM_PROCS-1;
				end			
				else if(rr_counter==(MAX_NUM_PROCS-1)) begin
					rr_counter_next = 0;
				end
				*/
				rr_counter_next = rr_counter+1;
				state_next = IDLE;
			end
			//register the select signal
			else begin
				snoopy_bus_grant_internal_next[rr_counter] 	= 1'b1; 	
				winner_next 					= rr_counter;	
				state_next 					= GRANT;
			end
		end

		GRANT: begin
			if(snoopy_bus_release) begin
				snoopy_bus_grant_internal_next[rr_counter] 	= 1'b0; 	
				/*
				if(rr_counter==(max_fpga_procs-1)) begin
					rr_counter_next = MAX_NUM_PROCS-1;
				end			
				else if(rr_counter==(MAX_NUM_PROCS-1)) begin
					rr_counter_next = 0;
				end	
				*/
				rr_counter_next = rr_counter+1;
				state_next 					= IDLE;
				winner_next 					= 0;
			end
		end
	endcase
end

always@(posedge clk)
begin
	if(reset) begin
		state 		<= IDLE;
		snoopy_bus_grant_internal 	<= 0;
		winner		<= 0;
		rr_counter	<= 0;
	end
	else begin
		state 		<= state_next;
		snoopy_bus_grant_internal	<= snoopy_bus_grant_internal_next;
		winner		<= winner_next;
		rr_counter	<= rr_counter_next;
	end
end

/*
always@(*)
begin
	casex(bus_request_internal)
		2'b00:	sel_encoded = 0;
		2'b01:	sel_encoded = 0;
		2'b10:	sel_encoded = 1;
		2'b11:	sel_encoded = 0;
	endcase
end
*/

/*
always@(*)
begin
	casex(bus_request_internal)
		4'b0000:	sel_encoded = 0;
		4'b0001:	sel_encoded = 0;
		4'b001x:	sel_encoded = 1;
		4'b01xx:	sel_encoded = 2;
		4'b1xxx:	sel_encoded = 3;
	endcase
end
*/
/*
always@(*)
begin
	casex(bus_request_internal)
		8'b00000000:	sel_encoded = 0;
		8'b00000001:	sel_encoded = 0;
		8'b0000001x:	sel_encoded = 1;
		8'b000001xx:	sel_encoded = 2;
		8'b00001xxx:	sel_encoded = 3;
		8'b0001xxxx:	sel_encoded = 4;
		8'b001xxxxx:	sel_encoded = 5;
		8'b01xxxxxx:	sel_encoded = 6;
		8'b1xxxxxxx:	sel_encoded = 7;


	endcase
end
*/
/*
always@(*)
begin
	casex(bus_request_internal)
		8'b00000000:	sel_encoded = 0;
		8'bxxxxxxx1:	sel_encoded = 0;
		8'bxxxxxx10:	sel_encoded = 1;
		8'bxxxxx100:	sel_encoded = 2;
		8'bxxxx1000:	sel_encoded = 3;
		8'bxxx10000:	sel_encoded = 4;
		8'bxx100000:	sel_encoded = 5;
		8'bx1000000:	sel_encoded = 6;
		8'b10000000:	sel_encoded = 7;


	endcase
end
*/
endmodule
