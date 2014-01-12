module term_check_pr #(
	parameter TOTAL_KEYS = 8,
	parameter PROC_ID = 0
) (
	input clk,
	input reset,

	input [31:0] 	  num_keys,
	//iteration accumulation
	output reg 	  iteration_accum_buffer_rdreq,
	input wire [63:0] iteration_accum_buffer_dataout,
	input wire 	  iteration_accum_buffer_empty,

	output reg [31:0] accum_value,
	input [31:0]      log_2_num_workers_in
);


localparam ADD_CYCLES = 8;

localparam NUM_STATES		=4;
localparam IDLE			=1;
localparam WAIT			=2;
localparam ADD 			=4;
localparam FREEZE		=8;

reg iteration_accum_buffer_rdreq_next;
reg [NUM_STATES-1:0] state, state_next;
reg [ADD_CYCLES-1:0] timeout_reg, timeout_reg_next;
reg [31:0] iteration_accum_result;
reg [31:0] iteration_accum_result_next;
reg [31:0] counter, counter_next;
reg [31:0] accum_value_next;

function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
endfunction // log2

wire[31:0] add_result;
reg clk_en;
wire [31:0] lfsr_addr;

assign lfsr_addr = iteration_accum_buffer_dataout[63:32]>>log_2_num_workers_in;

//A floating point adder to calculate the iteration accumulate value
float_add_sub float_add_sub(
        .clock  	(clk),
	.clk_en		(clk_en),
        .dataa  	(iteration_accum_result),
        .datab  	(iteration_accum_buffer_dataout[31:0]),
        .overflow	(overflow),
        .result 	(add_result)
);

wire add_result_higher_than_latest_accum_value;
/*A comparator for floating point comparisons*/
float_cmp fcomp (
        .clk_en         (1'b1),
        .clock          (clk),
        .dataa          (add_result),
        .datab          (accum_value),
        .ageb           (add_result_higher_than_latest_accum_value)
);




reg add_done, add_done_next;
always@(posedge clk)
begin
	if(reset) begin
		accum_value <= 0;
	end
	else begin
		if(add_result_higher_than_latest_accum_value&add_done)
			accum_value <= add_result;
		else
			accum_value <= accum_value+0;
	end
end


//assign accum_value = iteration_accum_result;
always@(*)
begin
	iteration_accum_result_next = iteration_accum_result;
	iteration_accum_buffer_rdreq_next = 1'b0;
	state_next = state;
	timeout_reg_next = timeout_reg;
	counter_next = counter;
	//accum_value_next = accum_value;
	add_done_next = 0;
	case(state)
		IDLE: begin
			if(!iteration_accum_buffer_empty) begin
				iteration_accum_buffer_rdreq_next = 1'b1;
				state_next = WAIT;
			end
		end

		WAIT:begin
			state_next = ADD;
			timeout_reg_next = 1'b1<<(ADD_CYCLES-1);
		end

		ADD: begin
			if(timeout_reg==0) begin
				add_done_next = 1'b1;
				iteration_accum_result_next = (lfsr_addr==PROC_ID)?0:add_result;
				//accum_value_next = (lfsr_addr==0)?add_result:accum_value;			
				state_next = (add_result==32'h7fc00000)?FREEZE:IDLE;
			end			
			else begin
				timeout_reg_next = timeout_reg>>1;
			end
		end

		FREEZE: begin
			state_next = FREEZE;
		end

		default: begin
			state_next = IDLE;
		end
	endcase
end

always@(posedge clk) 
begin
	if(reset) begin
		state 		<= IDLE;
		timeout_reg 	<= 0;
		iteration_accum_result <= 0;
		//accum_value 	<= 0;
		counter		<= 0;
		iteration_accum_buffer_rdreq <= 0;
		clk_en 		<= 0;
		//accum_value	<= 0;
		add_done	<= 0;
	end 
	else begin	
		state 		<= state_next;
		timeout_reg 	<= timeout_reg_next;
		counter		<= counter_next;
		//iteration_accum_result <= (counter==0)?iteration_accum_buffer_dataout[31:0]:iteration_accum_result_next;
		//iteration_accum_result <= (counter==0)?0:iteration_accum_result_next;
		iteration_accum_result <= iteration_accum_result_next;
		//accum_value 	<= (counter==num_keys-1)?iteration_accum_result:accum_value;
		//accum_value 	<= accum_value_next; //(lfsr_addr==0)?add_result:accum_value;
		iteration_accum_buffer_rdreq <= iteration_accum_buffer_rdreq_next;
		clk_en		<= (state_next==ADD)?1'b1:1'b0;
		add_done	<= add_done_next;
	end
end

endmodule

//assign temp = user_buffer_output_data[63:32]; //accumulate value field
/*
assign accum_value_next = ((lfsr_address_out==0)&&(sort_wren==1'b1))?temp:
                          ((sort_wren==1'b1))?(accum_value+temp):
                          accum_value;
*/
/*
assign accum_value_next = ((lfsr_address_out==0)&&(sort_wren==1'b1))?temp:
                          ((sort_wren==1'b1))?(iteration_accum_result):
                          accum_value;
*/
