
//capture finish from all processing unist
module finish_bit (
	input 		clk,
	input 		reset,

	input 		clear_finish_reg,
	input 		set_finish,
	output reg 	finish_reg
);

always@(posedge clk)
begin
	if(reset) begin
		finish_reg <= 0;
	end
	else if(clear_finish_reg) begin
		finish_reg <= 0;
	end
	else begin
		if(set_finish)
			finish_reg <= 1'b1;
		else
			finish_reg <= finish_reg|0; //avoid a latch!
	end
end
endmodule
