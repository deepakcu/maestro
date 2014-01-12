`timescale 1ns/1ps

module sort_module #(
	parameter K = 128,
	parameter SORT_WIDTH=32,
	parameter PRI_POS_START = 0,
	parameter PRI_POS_END = 32

)(
	input clk,
	input reset,
	
	input sort_en,
	input place_en,
	input wren,
	input order,
	input [SORT_WIDTH-1:0] data_in, //we bring  [key,val,delta_val,priority,pointer to data, length of dataset] in single clk cycle
	output [SORT_WIDTH-1:0] dataout_sig,
	//signals to check for mutual exclusion between accumulator and update module
	input [31:0] accum_key,
	//output [K-1:0] is_equal,
	//output [K*32-1:0] sort_keys,
	//output reg [K-1:0] mask_reg,
	
	input shift_out,
	output [31:0] threshold
);

//reg [K-1:0] mask_reg_next;
wire [SORT_WIDTH-1:0] prev_data[K-1:0];

wire [K-1:0] i_am_lower;

wire [K-1:0] is_equal;

wire write_en;
assign write_en = wren & sort_en;
//assign dataout_sig = prev_data[K-1];

/*

generate
	for(i=0;i<K;i=i+1) begin:equal
		//assign is_equal[i] = (accum_key==prev_data[i][31:0])?1'b1:1'b0;
		assign sort_keys[32*(i+1)-1:32*i] = prev_data[i][31:0];
	end
endgenerate
*/
/*
always@(*) 
begin
	if(mask_reg==0)
		mask_reg_next = {K{1'b1}};
	else if(shift_out)
		mask_reg_next = mask_reg>>1;
	else
		mask_reg_next = mask_reg;
end

always@(posedge clk)
begin
	if(reset)
		mask_reg <= {K{1'b1}}; 
	else
		mask_reg <= mask_reg_next;
end
*/

//assign threshold = next_data[K-1][63:32];//dataout_sig[63:32];
//assign threshold = prev_data[K-1][63:32];//dataout_sig[63:32];
assign threshold = prev_data[K-1][31:0];//dataout_sig[63:32];

genvar i;
generate
	for(i=0;i<K;i=i+1) begin:sort
	if(i==0) begin
		sort_cell #(
        	.SORT_WIDTH(SORT_WIDTH),
			.PRI_POS_START(PRI_POS_START),
			.PRI_POS_END(PRI_POS_END)
		) scell (
        	.clk	(clk),
        	.reset	(reset),

        	//.prev_data	({SORT_WIDTH{1'b1}}),
				//  multfact, size, ptr,  pri  , deltav, val, key
		//Forward shift path
		//.prev_data	({32'h7F800000,32'h0}), //deltav is set to + infinity for single-precision floating point
		.prev_data	(32'h7F800000), //deltav is set to + infinity for single-precision floating point
        	.data_out	(prev_data[0]),

        	.datain		(data_in),
		.place_en	(place_en),
        	.wren		(write_en),
		.order		(order),

        	.left_is_lower	(1'b0),
        	.i_am_lower	(i_am_lower[0])
	);
	end
	else if(i==K-1) begin //last cell
		sort_cell #(
        		.SORT_WIDTH(SORT_WIDTH),
			.PRI_POS_START(PRI_POS_START),
			.PRI_POS_END(PRI_POS_END)
		) scell (
        	.clk	(clk),
        	.reset	(reset),

		//Forward shift path
        	.prev_data	(prev_data[i-1]),
        	.data_out	(prev_data[i]),

        	.datain		(data_in),
		.place_en	(place_en),
        	.wren		(write_en),
		.order		(order),

        	.left_is_lower	(i_am_lower[i-1]),
        	.i_am_lower	(i_am_lower[i])
	);
	end
	else begin
		sort_cell #(
        	.SORT_WIDTH(SORT_WIDTH),
			.PRI_POS_START(PRI_POS_START),
			.PRI_POS_END(PRI_POS_END)
		) scell (
        	.clk	(clk),
        	.reset	(reset),

		//Forward shift path
        	.prev_data	(prev_data[i-1]),
        	.data_out	(prev_data[i]),

		.datain		(data_in),
		.place_en	(place_en),
        	.wren		(write_en),
		.order		(order),

        	.left_is_lower	(i_am_lower[i-1]),
        	.i_am_lower	(i_am_lower[i])
		  
	);
	end
	end
endgenerate

endmodule
