`timescale 1ns/1ps

module snooper #(
	parameter MAX_LOCK_KEYS=4
) (
	input clk,
	input reset,

	input 				snoop_check,
	input [31:0]			snoop_bus,
	
	output reg			add_conflict,
	input [31:0]			locked_key[MAX_LOCK_KEYS-1:0]
	//input [MAX_LOCK_KEYS-1:0]	match_lines
);

//assign add_conflict = (snoop_check&locked_valid_bit&(snoop_bus==locked_key))?1'b1:1'b0; 

wire[MAX_LOCK_KEYS-1:0] match;
wire			any_match;

genvar i;
generate
	for(i=0;i<MAX_LOCK_KEYS;i=i+1) begin:chk
		assign match[i]=((snoop_bus==locked_key[i])&snoop_check)?1'b1:1'b0;
	end
endgenerate

assign any_match = |match;
//assign any_match = |match_lines;


always@(posedge clk)
begin
	if(reset) begin
		add_conflict <= 1'b0;
	end
	else begin
		if(snoop_check & any_match) 
			add_conflict <= 1'b1;
		else
			add_conflict <= 1'b0;
	end
end
endmodule
