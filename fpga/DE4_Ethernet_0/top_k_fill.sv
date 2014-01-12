//State machine that will fill the top K sort cells
//On receiving the start_update signal go high, this sm will generate
//random addresses and use that to fill the top k select module
//once this statemachine is done, it will assert the signal top_k_fill_done


module top_k_fill #(
	parameter DEFAULT_READ_LENGTH = 32,
        parameter FIFO_DATA_WIDTH = 64,
        parameter MAX_NUM_PROCS = 8,
        parameter DATA_WIDTH = 32,
        parameter SAMPLE_SIZE = 512,
        parameter DDR_BASE = 0, //31'h00000000,
        parameter DDR_SIZE = 1073741824, //1Gb
        parameter ADDRESS_WIDTH = 31,
        parameter MAX_N_VALUES = 128, //number of items in sorted list
	parameter MAX_K_VALUES = 4,	
        parameter TOTAL_KEYS = 8,
	parameter SORT_WIDTH = 1*DATA_WIDTH
)
(
	input clk,
	input reset,

	
	//ddr
	output wire				control_fixed_location,
	output reg [ADDRESS_WIDTH-1:0]        	control_read_base,	
	output reg [ADDRESS_WIDTH-1:0]         	control_read_length,
	output reg                             	control_go,
	input wire 				control_done,		

	output reg                             	user_read_buffer,
	input wire 				user_data_available,
	input wire [255:0]			user_buffer_data,
	
	//misc	
	input [31:0]		num_keys,

	input			start_update,
	input wire		almost_empty,
	input wire [31:0] 	max_n_values,
	output reg 		start_key_process,
	input			start_key_selection[MAX_NUM_PROCS-1:0],

	output wire [31:0] 	threshold
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


localparam NUM_STATES	=9;
localparam IDLE		=0;           
localparam GEN_ADDR	=1;
localparam PLACE_ADDR	=2;  
localparam WAIT_CYCLE   =3;      
localparam READ_DATA	=4;         
localparam PLACE_EN	=5;
localparam WRITE_SORT	=6;
localparam ORDER	=7;
localparam SHIFT_OUT	=8;

///////////////Wires and registers////////
//---LFSR---
reg 				lfsr_enable;
wire [31:0] 	lfsr_address_out;
wire [31:0] 	lfsr_start;


reg [log2(NUM_STATES)-1:0]            state, state_next;
reg 			sort_en, sort_en_next;
reg 			sort_wren, sort_wren_next;
reg			place_en, place_en_next; 
reg  			order, order_next;

//---DDR master controller---
reg [ADDRESS_WIDTH-1:0]         control_read_length_next;
reg                             control_go_next;
//---misc---
//reg [log2(MAX_N_VALUES)-1:0]    sample_cnt, sample_cnt_next;
reg [31:0]    			sample_cnt, sample_cnt_next;

reg                             internal_sort_reset, internal_sort_reset_next;

reg 					lfsr_enable_next;
reg 					user_read_buffer_next;
reg [ADDRESS_WIDTH-1:0]        		control_read_base_next;
reg 					start_key_process_next;
wire [MAX_NUM_PROCS-1:0] 			finish_reg;
wire					all_update_done;
reg				   clear_finish_reg,clear_finish_reg_next;
//assign all_update_done = &finish_reg;
assign all_update_done = finish_reg[0];
assign control_fixed_location = 0;


wire [31:0] max_n_minus_one;
wire sort_reset;
//////////////////////////////////////////////////////////////////


lfsr #(
        .MAX_ADDR_VAL(256)
) lfsr (
   .num_keys	(num_keys),
   .lfsr_out 	(lfsr_address_out),
   .lfsr_start  (lfsr_start),
   .enable 	(lfsr_enable),
   .clk		(clk),
   .reset	(reset)
);

assign sort_reset = reset|internal_sort_reset;
/*
sort_module #(
        .K(MAX_K_VALUES),
      	//.SORT_WIDTH(SORT_WIDTH),
	.SORT_WIDTH(SORT_WIDTH), //optimized sort module only two fields - key and priority field [for pagerank -> key, deltaval]
	.PRI_POS_START(32), //priority is always the upper 32 bits passed into the sort module [bits 32 to 63]
	.PRI_POS_END	(64)
) sort_module (
   .clk		(clk),
   .reset	(sort_reset),

   .sort_en	(sort_en),
   .place_en	(place_en),
   .wren	(sort_wren),
   .order	(order),
   .data_in	({user_buffer_data[95:64],user_buffer_data[31:0]}), //the sort module uses key and delta value
   .dataout_sig	(data_out_sort),
   .threshold	(threshold)
);
*/
sort_module #(
        .K(MAX_K_VALUES),
      	//.SORT_WIDTH(SORT_WIDTH),
	.SORT_WIDTH(SORT_WIDTH), //optimized sort module only two fields - key and priority field [for pagerank -> key, deltaval]
	.PRI_POS_START(0), //priority is always the upper 32 bits passed into the sort module [bits 32 to 63]
	.PRI_POS_END	(32)
) sort_module (
   .clk		(clk),
   .reset	(sort_reset),

   .sort_en	(sort_en),
   .place_en	(place_en),
   .wren	(sort_wren),
   .order	(order),
   .data_in	(user_buffer_data[95:64]), //the sort module uses key and delta value
   .dataout_sig	(data_out_sort),
   .threshold	(threshold)
);


//////////////////////////////////////////////////////////////////
assign max_n_minus_one = max_n_values-1;

always@(*)
begin
	state_next 			= state;
	sort_en_next 			= sort_en;
	sample_cnt_next 		= sample_cnt;
	lfsr_enable_next 		= 1'b0;
	control_read_base_next 		= control_read_base;
	control_read_length_next 	= control_read_length;
	control_go_next 		= 1'b0;
	sort_wren_next 			= 1'b0;
	user_read_buffer_next 		= 1'b0;
	sort_wren_next 			= 1'b0;
	order_next 			= 1'b0;
	place_en_next			= 1'b0;
	internal_sort_reset_next 	= 0;
	start_key_process_next 		= 0;
	clear_finish_reg_next		= 0;

	case(state)
               IDLE:begin
			sample_cnt_next = 0;
			if(start_update) begin		
				state_next = GEN_ADDR;
				sort_en_next = 1'b1;
				lfsr_enable_next = 1'b1;
			end
			else begin
				state_next = IDLE;
				sort_en_next = 1'b0;
				lfsr_enable_next = 1'b0;
			end
		end

		GEN_ADDR: begin			
			state_next = PLACE_ADDR;
		end

                PLACE_ADDR: begin
                        if(lfsr_address_out>=num_keys) begin //Deepak - switch to configurable number of keys
                                lfsr_enable_next = 1'b1; //RETRY until we get a valid address
		                state_next = GEN_ADDR;
                        end
                        else begin
                		lfsr_enable_next = 1'b0;
                                control_read_base_next = DDR_BASE+(lfsr_address_out<<5); //Each word for a key in DRAM is 8 32 bit integers - So convert LFSR address into multiple of 32                  
                                state_next = WAIT_CYCLE;
                                control_read_length_next = DEFAULT_READ_LENGTH;
                                control_go_next = 1'b1;
			end			
		end

		WAIT_CYCLE: begin
			if(user_data_available) begin
				state_next = READ_DATA;
			end
		end

                READ_DATA: begin
			casex({user_data_available,control_done})
                                2'b00:begin //both user data  and control done are not available - wait here
                                        state_next = READ_DATA;
                                end
                                2'b01:begin //this condition should not happen!
                                        state_next = READ_DATA;
                                end
                                2'b1x:begin 
                                        state_next = PLACE_EN; //READ_DATA;
                                        place_en_next = 1'b1;
	                                sample_cnt_next = sample_cnt + 1;
                                end
                                default: state_next = ORDER;
                        endcase
                end

		PLACE_EN: begin //floating point comparisons take 1 cycle in sort_cell - this new state accounts for the additional 1 cycle
                        sort_wren_next = 1'b1;
			state_next = (user_data_available&control_done)?ORDER:WRITE_SORT;
			user_read_buffer_next = 1'b1;
		end

		WRITE_SORT: begin
			state_next = READ_DATA;
		end	

		ORDER:begin
			order_next = 1'b1;
			if(sample_cnt==max_n_minus_one) begin
				state_next 			= SHIFT_OUT;
				lfsr_enable_next 		= 1'b0;
				start_key_process_next 		= 1'b1;
			end
			else begin
				if(start_update) begin
					state_next = GEN_ADDR;
					lfsr_enable_next = 1'b1;
				end
				else begin
					state_next = IDLE;
					lfsr_enable_next = 1'b0;
				end
			end
			
		end

		SHIFT_OUT:begin
			if(all_update_done) begin
				state_next = IDLE;
				clear_finish_reg_next = 1'b1;
				internal_sort_reset_next = 1'b1;
			end
		end

		default: begin
			state_next = IDLE;
		end
	endcase
end

always@(posedge clk)
begin
	if(reset) begin
		state 				<= IDLE;
        	sort_en 			<= 1'b0;
	        sample_cnt	 		<= 0;
        	lfsr_enable	 		<= 0;
	        control_read_base 		<= 0;
        	control_read_length	 	<= 0;
	        control_go	 		<= 0;
        	sort_wren 			<= 0;
		user_read_buffer		<= 0;
		order				<= 0;
		place_en			<= 0;
		internal_sort_reset		<= 0;
		start_key_process		<= 0;
		clear_finish_reg		<= 0;
	end
	else begin
		state 				<= state_next;
        	sort_en 			<= sort_en_next;
	        sample_cnt			<= sample_cnt_next;
        	lfsr_enable	 		<= lfsr_enable_next;
	        control_read_base 		<= control_read_base_next;
        	control_read_length	 	<= control_read_length_next;
	        control_go	 		<= control_go_next;
        	sort_wren 			<= sort_wren_next;
		user_read_buffer		<= user_read_buffer_next;
		order				<= order_next;
		place_en			<= place_en_next;
		internal_sort_reset		<= internal_sort_reset_next;
		start_key_process		<= start_key_process_next;
		clear_finish_reg		<= clear_finish_reg_next;
	end

end



genvar i;
generate
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin:f
	finish_bit finish_bit (
		.clk		(clk),
		.reset		(reset),

		.clear_finish_reg	(clear_finish_reg),
		.set_finish		(start_key_selection[i]),
		.finish_reg		(finish_reg[i])
	);
	
end
endgenerate


endmodule
