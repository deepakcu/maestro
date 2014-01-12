`timescale 1ns/1ps

module link_read #(
	parameter DATA_WIDTH=32,
	parameter ADDRESS_WIDTH=31,
	parameter DDR_BASE=0,
	parameter DEFAULT_READ_LENGTH=32,
	parameter LINK_GEN_FIFO_WIDTH=DATA_WIDTH*2,
	parameter COMPUTE_LINK_FIFO_WIDTH=DATA_WIDTH*3
) (
	input clk,
	input reset,
 
	input [COMPUTE_LINK_FIFO_WIDTH-1:0] 	compute_link_fifo_q,
	input 					compute_link_fifo_empty,
	output reg				compute_link_fifo_rdreq,

	output reg [LINK_GEN_FIFO_WIDTH-1:0] 	link_gen_fifo_data,
	input 					link_gen_fifo_full,
	output reg				link_gen_fifo_wrreq,

	output reg 				link_user_read_buffer,
	input wire 				link_user_data_available,
	input [255:0] 				link_user_buffer_data,

	input [31:0]				log_2_num_workers_in,
	input [31:0]				shard_id,
	
	output wire			      	link_control_fixed_location,
	output reg [ADDRESS_WIDTH-1:0]        	link_control_read_base,	
	output reg                             	link_control_go,
	output reg [ADDRESS_WIDTH-1:0]         	link_control_read_length,
	input wire 			       	link_control_done,

	//external fifo 
	output reg [63:0] 			ext_fifo_data,
	output reg     				ext_fifo_wrreq,
	input         				ext_fifo_full,
	input [31:0]				threshold	
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

localparam NUM_STATES		= 9;
localparam IDLE			= 0;
localparam READ_FIFO 		= 1;
localparam PARSE_KEY 		= 2;
localparam FETCH_LINK_RECORD 	= 3;
localparam WAIT_LINK_RECORD 	= 4;
localparam READ_LINK_RECORD 	= 5;
localparam FETCH_LINK 		= 6;
localparam PUSH_LINK 		= 7;
localparam INC_LINK 		= 8;

//registers and wires
reg [log2(NUM_STATES)-1:0]	state, state_next;
reg [ADDRESS_WIDTH-1:0]         link_control_read_base_next;	
reg [ADDRESS_WIDTH-1:0]         link_control_read_length_next;
reg                             link_control_go_next;
reg				compute_link_fifo_rdreq_next;
reg [LINK_GEN_FIFO_WIDTH-1:0] 	link_gen_fifo_data_next;
reg				link_gen_fifo_wrreq_next;

wire [31:0] mask;
assign mask = ~({32{1'b1}}<<log_2_num_workers_in);

reg [31:0] 	msg, msg_next;
reg [31:0]	data_ptr, data_ptr_next;
reg [31:0]	data_size, data_size_next;
reg 		link_user_read_buffer_next;

wire [31:0] 	links[7:0];
reg  [31:0] 	link_word_cnt, link_word_cnt_next;
reg  [255:0] 	link_record, link_record_next;
reg  [31:0] 	link,link_next;
reg  [2:0] 	link_select, link_select_next;
wire [31:0] 	selected_link_id;

reg [63:0] 	ext_fifo_data_next;
reg		ext_fifo_wrreq_next;

genvar i;
generate
for(i=0;i<8;i=i+1) begin:link_sep
	assign links[i]=link_record[(i+1)*32-1:i*32];
end
endgenerate
assign selected_link_id=links[link_select];

wire [31:0] num_link_words;
assign num_link_words = (data_size[2:0]==0)?(data_size>>3):((data_size>>3)+1);
assign link_control_fixed_location = 0;

wire large_msg;
/*A comparator for floating point comparisons*/
float_cmp fcomp (
        .clk_en         (1'b1),
        .clock          (clk),
        .dataa          (msg), //delta_val
//	.datab          (threshold),
	.datab		(32'h358637bd), //deepak - commented for katz
//      .datab		(32'h0),
        .ageb           (large_msg)
);



always@(*)
begin

	state_next 			= state;
	link_gen_fifo_data_next 	= link_gen_fifo_data;
	link_gen_fifo_wrreq_next 	= 0;
	compute_link_fifo_rdreq_next 	= 0;

	link_user_read_buffer_next 	= 0;
        link_control_go_next 		= 0;
	link_control_read_base_next	= link_control_read_base;
        link_control_read_length_next 	= link_control_read_length;

	msg_next			= msg;	
	data_ptr_next			= data_ptr;
	data_size_next			= data_size;
	link_word_cnt_next		= link_word_cnt;
	link_record_next 		= link_record;
	link_select_next		= link_select;
	link_next			= link;

	ext_fifo_data_next		= ext_fifo_data;
	ext_fifo_wrreq_next		= 0;

	case(state)
		IDLE: begin
			if(!compute_link_fifo_empty) begin
				compute_link_fifo_rdreq_next = 1;
				state_next = READ_FIFO;
			end
		end

		READ_FIFO: begin
			state_next = PARSE_KEY;
		end
	
		PARSE_KEY: begin
			data_ptr_next 		= compute_link_fifo_q[95:64];
			data_size_next 		= compute_link_fifo_q[63:32];
			msg_next		= compute_link_fifo_q[31:0];
			link_word_cnt_next	= 0;
			link_select_next	= 0;
			state_next		= FETCH_LINK_RECORD;
		end

		FETCH_LINK_RECORD: begin
			if(link_word_cnt<num_link_words) begin
				link_word_cnt_next 		= link_word_cnt+1;
				link_control_read_base_next	= DDR_BASE+data_ptr+(link_word_cnt<<5);	//IF using DDR memory uncomment line
				//link_control_read_base_next 	= DDR_BASE+((data_ptr+link_word_cnt)<<5); //enable for simulation ONLY
				link_control_read_length_next 	= DEFAULT_READ_LENGTH;
				link_control_go_next 		= 1'b1;
				state_next 			= WAIT_LINK_RECORD;
			end
			else begin
				link_word_cnt_next		= 0;
				state_next			= IDLE;
			end
		end
		
		WAIT_LINK_RECORD: begin
			if(link_user_data_available) begin //deepak - debug:latchup
		                link_user_read_buffer_next 	= 1'b1;
                                state_next 			= READ_LINK_RECORD;
                        end
		end

		READ_LINK_RECORD: begin
			link_record_next= link_user_buffer_data;
			state_next 	= FETCH_LINK;
		end

		//will need to modify this part for multi board setup
		FETCH_LINK: begin
			if(selected_link_id==32'hFFFFFFFF) begin
				state_next 		= FETCH_LINK_RECORD;
			end
			else if((selected_link_id&mask)!=shard_id) begin //seperate external updates
				//katz comment
				if(threshold==0) begin
				 	if(!ext_fifo_full) begin
						ext_fifo_data_next = {selected_link_id,msg};
						ext_fifo_wrreq_next = 1'b1;
						state_next = INC_LINK;
					end
				end 
				else begin
					if(!large_msg) begin //ignore small messages that are sent outside of FPGA
					//if((!large_msg)&&(threshold!=0)) begin //ignore small messages that are sent outside of FPGA
						state_next = INC_LINK;
					end
					else if(!ext_fifo_full) begin
						ext_fifo_data_next = {selected_link_id,msg};
						ext_fifo_wrreq_next = 1'b1;
						state_next = INC_LINK;
					end 
				end
			end
			else begin
				link_next 		= links[link_select];
				state_next 		= PUSH_LINK;
			end
		
		end
		
		PUSH_LINK: begin
			if(!link_gen_fifo_full) begin
				link_gen_fifo_wrreq_next= 1;
				link_gen_fifo_data_next = {link,msg};
				state_next		= INC_LINK;
			end
		end

		INC_LINK:begin
				if(link_select==7) begin //we processed all links in this record - fetch the next one
					link_select_next	= 0;
					state_next 		= FETCH_LINK_RECORD;
				end
				else begin //fetch the new link in the record
					link_select_next	= link_select+1;
					state_next 		= FETCH_LINK;
				end

		end
		
		default: state_next = IDLE;
	endcase
end

always@(posedge clk) begin
	if(reset) begin
		state 				<= IDLE;

		msg 				<= 0;
		data_ptr 			<= 0;
		data_size 			<= 0;

		link_select 			<= 0;
		link_word_cnt 			<= 0;
		link_record 			<= 0;
	
		link_gen_fifo_wrreq 		<= 0;
		link_gen_fifo_data 		<= 0;
		compute_link_fifo_rdreq 	<= 0;

		link_user_read_buffer		<= 0;
        	link_control_go			<= 0;
		link_control_read_base 		<= 0;
        	link_control_read_length 	<= 0;
		link				<= 0;

		ext_fifo_data			<= 0;
		ext_fifo_wrreq			<= 0;

	end
	else begin
		state 				<= state_next;
		link_gen_fifo_data 		<= link_gen_fifo_data_next;
		link_gen_fifo_wrreq 		<= link_gen_fifo_wrreq_next;
		compute_link_fifo_rdreq 	<= compute_link_fifo_rdreq_next;

		link_user_read_buffer 		<= link_user_read_buffer_next;
        	link_control_go			<= link_control_go_next;
		link_control_read_base 		<= link_control_read_base_next;
        	link_control_read_length 	<= link_control_read_length_next;

		msg				<= msg_next;	
		data_ptr			<= data_ptr_next;
		data_size			<= data_size_next;
	
		link_word_cnt			<= link_word_cnt_next;
		link_record 			<= link_record_next;
		link_select			<= link_select_next;
		link				<= link_next;

		ext_fifo_data			<= ext_fifo_data_next;
		ext_fifo_wrreq			<= ext_fifo_wrreq_next;
	end
end
endmodule
