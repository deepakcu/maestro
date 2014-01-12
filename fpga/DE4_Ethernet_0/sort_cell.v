`timescale 1ns/1ps

module sort_cell #(
	parameter SORT_WIDTH=32,
	parameter SHIFT_INPUT_WIDTH=8,
	parameter PRI_POS_START=0,
	parameter PRI_POS_END=32
) (
	input clk,
	input reset,

	//Forward shift path
	input [SORT_WIDTH-1:0] prev_data,
	output [SORT_WIDTH-1:0] data_out,

	input [SORT_WIDTH-1:0] datain,
	input		       place_en,
	input		       wren,
	input		       order,


	input left_is_lower, 
	output i_am_lower  //if (datain>= data_out), ly is set otherwise reset

);

reg [SORT_WIDTH-1:0] datain_stored;
reg [SORT_WIDTH-1:0] current;
assign data_out = current;


reg is_lower, is_lower_next;
wire aleb;

wire [31:0] current_priority;
wire [31:0] datain_priority;

assign current_priority = current[PRI_POS_END-1:PRI_POS_START];
assign datain_priority = datain[PRI_POS_END-1:PRI_POS_START];



assign i_am_lower = is_lower;

//data in is [key, val, delta, pri, ptr]
//look at pri field for comparison
//assign i_am_bigger = (current[PRI_POS_END-1:PRI_POS_START]>datain[PRI_POS_END-1:PRI_POS_START])?1'b1:1'b0;


/*A comparator for floating point comparisons*/
float_cmp fcomp (
        .clk_en 	(place_en), //when the place_en is high, the floating_cmp compares the data and produces aleb - This result will be used 1 cycle later when wren is asserted
        .clock  	(clk),
        .dataa	(current_priority),
        .datab	(datain_priority),
        .aleb	(aleb)
);


always@(posedge clk) 
begin
	if(reset) begin
		current <= 0;
		is_lower <= 0;
		datain_stored <= 0;
	end
	else begin
		if(wren) begin
			current <= current;
			is_lower <= (aleb)?1'b1:1'b0; //(current_priority<=datain_priority)?1'b1:1'b0;
		end
		else if(order) begin //this logic will make the logic shift right (if the cell's value is lower than the incoming data value)
			is_lower <= is_lower;
			case({left_is_lower,i_am_lower})
				2'b01: 		current <= datain_stored;
				2'b11: 		current <= prev_data;
				default: 	current <= current;
			endcase
		end
		else begin
			current <= current;
			is_lower <= is_lower;
		end
		datain_stored <= datain;
	end
	

end

endmodule
