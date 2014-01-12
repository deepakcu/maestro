//written by lgk

`timescale 1ns/1ps

module gen_addr #(
	parameter DATA_WIDTH=32,
	parameter PROC_ID=0,
	parameter MAX_NUM_PROCS = 2,
	parameter LINK_GEN_FIFO_WIDTH=64,
	parameter GEN_LOCK_FIFO_WIDTH=65,
	parameter UPDATE_MODE=0,
	parameter ACCUM_MODE=1
) (
	input clk,
	input reset,

	input [LINK_GEN_FIFO_WIDTH-1:0] 	link_gen_fifo_q,
	input 					link_gen_fifo_empty,
	output reg				link_gen_fifo_rdreq,

	input [63:0] 				rx_ext_update_q,
	input 					rx_ext_update_empty,
	output reg				rx_ext_update_rdreq,

	input [31:0]				log_2_num_workers_in,
	input [31:0]				shard_id,

	output reg [GEN_LOCK_FIFO_WIDTH-1:0] 	gen_lock_fifo_data,
	input 					gen_lock_fifo_full,
	output reg				gen_lock_fifo_wrreq,
	input 					compute_link_fifo_almost_full,

	input					start_update,
	input [31:0]				num_keys,
	output reg				start_key_selection,
	input [3:0]				max_fpga_procs,
	input 					process_ext_updates
	
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

localparam NUM_STATES		=4;
localparam IDLE			=0;
localparam GEN_KEY		=1;
localparam WAIT_LINK_READ	=2;
localparam WRITE_LINK		=3;

//registers and wires
reg [log2(NUM_STATES)-1:0]	state, state_next;

reg				link_gen_fifo_rdreq_next;
reg [GEN_LOCK_FIFO_WIDTH-1:0] 	gen_lock_fifo_data_next;
reg				gen_lock_fifo_wrreq_next;
reg				rx_ext_update_rdreq_next;

reg [DATA_WIDTH-1:0] key_cnt;
reg start_key_selection_next;
reg cnt_en, cnt_en_next;

wire keys_rollover;
//assign keys_rollover = (~(key_cnt<(num_keys-MAX_NUM_PROCS)));
assign keys_rollover = (~(key_cnt<(num_keys-max_fpga_procs)));


//assign keys_rollover = (~(key_cnt<((num_keys<<log_2_num_workers_in)-MAX_NUM_PROCS));


always@(*)
begin

	state_next 		 = state;
	gen_lock_fifo_data_next  = gen_lock_fifo_data;
	gen_lock_fifo_wrreq_next = 0;
	link_gen_fifo_rdreq_next = 0;
	start_key_selection_next = 0;
	cnt_en_next		 = 0;
	rx_ext_update_rdreq_next = 0;

	case(state)
		IDLE: begin
			if(process_ext_updates) begin
				if(!rx_ext_update_empty) begin
					rx_ext_update_rdreq_next = 1'b1;
					state_next = WAIT_LINK_READ;
				end
			end
			else begin
				if(start_update&link_gen_fifo_empty&(!compute_link_fifo_almost_full)) begin
					state_next = GEN_KEY;
				end
				else if(start_update&(!link_gen_fifo_empty)) begin
					link_gen_fifo_rdreq_next = 1'b1;
					state_next = WAIT_LINK_READ;
				end
				else begin
					state_next = IDLE;
				end
			end
		end

		GEN_KEY: begin
			if(!gen_lock_fifo_full) begin
				gen_lock_fifo_wrreq_next 	= 1'b1;
				gen_lock_fifo_data_next 	= {{1{UPDATE_MODE}},((key_cnt<<log_2_num_workers_in)+shard_id),32'b0}; //mode=update, key=key_cnt, msg=0
				cnt_en_next 			= 1'b1;
				state_next 			= IDLE;
				start_key_selection_next 	= (keys_rollover)?1'b1:1'b0;
			end
			else begin
				state_next = IDLE;
			end
		end

		WAIT_LINK_READ: begin
			state_next = WRITE_LINK;
		end

		WRITE_LINK: begin
			if(!gen_lock_fifo_full) begin
				if(process_ext_updates) begin
					gen_lock_fifo_data_next 	= {{1{ACCUM_MODE}},rx_ext_update_q}; //mode=accum, key=link key, msg=link msg
				end
				else begin
					gen_lock_fifo_data_next 	= {{1{ACCUM_MODE}},link_gen_fifo_q}; //mode=accum, key=link key, msg=link msg
				end
				gen_lock_fifo_wrreq_next 	= 1'b1;
				state_next 			= IDLE;
			end
		end
		
	endcase
end


always@(posedge clk)
begin
	if(reset) begin
		key_cnt <= PROC_ID;
	end 
	else if(cnt_en) begin
		if(!keys_rollover) begin
			//key_cnt <= (((((key_cnt-shard_id)>>log_2_num_workers_in)+MAX_NUM_PROCS)<<log_2_num_workers_in)+shard_id);
			//key_cnt <= (key_cnt+MAX_NUM_PROCS);
			key_cnt <= (key_cnt+max_fpga_procs);
		end
		else begin
			key_cnt <= PROC_ID;
		end
	end
end

always@(posedge clk) begin
	if(reset) begin
		state 				<= IDLE;
		gen_lock_fifo_data		<= 0;
		gen_lock_fifo_wrreq		<= 0;
		link_gen_fifo_rdreq		<= 0;
		start_key_selection		<= 0;
		cnt_en				<= 0;
		rx_ext_update_rdreq 		<= 0;
	end
	else begin
		state 				<= state_next;
		gen_lock_fifo_data		<= gen_lock_fifo_data_next;
		gen_lock_fifo_wrreq		<= gen_lock_fifo_wrreq_next;
		link_gen_fifo_rdreq		<= link_gen_fifo_rdreq_next;
		start_key_selection		<= start_key_selection_next;
		cnt_en				<= cnt_en_next;
		rx_ext_update_rdreq 		<= rx_ext_update_rdreq_next;
	end
end
endmodule
