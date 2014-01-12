module collector #(
	parameter MAX_NUM_PROCS=2
) (
	input clk,
	input reset,

	input [31:0] 	accum_value[MAX_NUM_PROCS-1:0],
	output reg [31:0]	iteration_accum_value,
	input [3:0]	max_fpga_procs
);


localparam ADD_CYCLES = 7;

localparam NUM_STATES		=2;
localparam IDLE			=1;
localparam WAIT_ADD	=2;


reg [NUM_STATES-1:0] state, state_next;
reg [ADD_CYCLES-1:0] timeout, timeout_next;
reg [31:0] iteration_accum_value_next;
reg [31:0] input_reg, input_reg_next;
reg [31:0] add_result_reg, add_result_reg_next;
reg [log2(MAX_NUM_PROCS)-1:0] select, select_next;

function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
endfunction // log2


wire [31:0] accumulated_val;
//A floating point adder to calculate the iteration accumulate value
float_add_sub float_add_sub(
        .clock  	(clk),
	.clk_en		(1'b1),
        .dataa  	(input_reg),
        .datab  	(add_result_reg),
        .overflow	(overflow),
        .result 	(accumulated_val)
);



always@(*)
begin

	add_result_reg_next = add_result_reg;
	iteration_accum_value_next = iteration_accum_value;
	state_next = state;
	timeout_next = timeout;
	select_next = select;
	input_reg_next = input_reg;
	case(state)
		IDLE:begin
			if(select==0) begin
				add_result_reg_next = 0;
				iteration_accum_value_next = accumulated_val;
			end
			else begin
				add_result_reg_next = accumulated_val;
			end
			timeout_next = 1'b1<<(ADD_CYCLES-1);
			state_next = WAIT_ADD;
			input_reg_next = accum_value[select];
		end
		
		WAIT_ADD: begin
			if(timeout==0) begin
				state_next = IDLE;
				//select_next = (select==(MAX_NUM_PROCS-1))?0:(select+1);
				select_next = (select==(max_fpga_procs-1))?0:(select+1);
			end
			else begin
				state_next = WAIT_ADD;
				timeout_next = timeout>>1;
			end
		end
		default:state_next = IDLE;

	endcase
end

always@(posedge clk)
begin
	if(reset) begin
		select			<= 0;
		add_result_reg 		<= 0;
		iteration_accum_value	<= 0;
		state	 		<= IDLE;
		timeout 		<= 0;
		input_reg		<= 0;
	end
	else begin
		select 			<= select_next;
		add_result_reg 		<= add_result_reg_next;
		iteration_accum_value	<= iteration_accum_value_next;
		state	 		<= state_next;
		timeout 		<= timeout_next;
		input_reg		<= input_reg_next;
	end
end
endmodule
