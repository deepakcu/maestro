
`timescale 1ns/1ps

//Reads from accumulate buffer and writes directly to indexed location in DRAM
module accumulator #(
	parameter DDR_BASE=31'h00000000,
	parameter ADDRESS_WIDTH=31
) (

	clk,
	reset,
	
	//External writes to accumulator
	
	accumulate_buffer_writedata,
	accumulate_buffer_slave_write,
	accumulate_buffer_waitrequest,
	

	//Local writes to accumulator
	accumulator_local_writedata,
	accumulator_local_wrreq,
	accumulator_local_full,
        accumulator_local_empty,	

	//Write interface to write into DDR memory
	wr_control_fixed_location,
	wr_control_write_base,
        wr_control_write_length,    
        wr_control_go,              
        wr_control_done,            

	wr_user_write_buffer,       
        wr_user_buffer_data,  
	wr_user_buffer_full,
	
	rd_control_fixed_location,
	rd_control_read_base,
	rd_control_read_length,
	rd_control_go,
	rd_control_done,

	rd_user_read_buffer,
	rd_user_buffer_data,
	rd_user_data_available,

	do_local_accumulate,
	end_local_accumulate,
	do_ext_accumulate,
	end_ext_accumulate,

	links_processed
	//log_2_num_workers_in
);

//max number of external updates that we perform before timing out
localparam MAX_EXT_UPDATES = 10;

localparam DATA_WIDTH=256;

localparam NUM_STATES=19;

localparam STATE_IDLE		=1;
localparam STATE_WAIT_READ	=2;
localparam STATE_READ_KEY_VAL	=3;
localparam STATE_READ_DELTA_VAL	=4;
localparam STATE_WAIT_DELTA_VAL	=5;
localparam STATE_READ_WAIT_CYCLE=6;
localparam STATE_ACCUMULATE	=7;

localparam WAIT_ADD_1		=8;
localparam WAIT_ADD_2		=9;
localparam WAIT_ADD_3		=10;
localparam WAIT_ADD_4		=11;
localparam WAIT_ADD_5		=12;
localparam WAIT_ADD_6		=13;

localparam STATE_UPDATE_DRAM	=14;
localparam STATE_WRITE_DRAM	=15;
localparam STATE_WAIT_DONE	=16;
localparam STATE_START_LOCAL_ACCUMULATE	=17;
localparam STATE_START_EXT_ACCUMULATE	=18;
localparam STATE_FINISH_ACCUMULATE	=19;
////////////Ports///////////////////
input clk;
input reset;

//Interface for external writes//
input [63:0] accumulate_buffer_writedata;
input        accumulate_buffer_slave_write;
output       accumulate_buffer_waitrequest;

//Signals for local accumulation
input [63:0] accumulator_local_writedata;
input        accumulator_local_wrreq;
output       accumulator_local_full;
output       accumulator_local_empty;

// Write control inputs and outputs
output wire 		wr_control_fixed_location;
output reg [30:0] 	wr_control_write_base;          
output reg [30:0] 	wr_control_write_length;        
output reg 		wr_control_go;
input wire 		wr_control_done;

// Write user logic inputs and outputs
output reg 			wr_user_write_buffer;                                
output reg [255:0] 		wr_user_buffer_data;          
input wire 			wr_user_buffer_full;                           

//Read control inputs and outputs
output wire       	rd_control_fixed_location;
output reg [30:0] 	rd_control_read_base;
output reg [30:0] 	rd_control_read_length;
output reg        	rd_control_go;
input             	rd_control_done;

output reg 		rd_user_read_buffer;
input wire [255:0] 	rd_user_buffer_data;
input wire 		rd_user_data_available;

input wire 	do_local_accumulate;
input wire      end_local_accumulate;
input wire 	do_ext_accumulate;
output reg      end_ext_accumulate;
output reg [31:0]	links_processed;
//input [31:0]    log_2_num_workers_in; //returns the log2(number of workers) - useful for mask calculation in key hashing

wire [31:0]    log_2_num_workers_in; //returns the log2(number of workers) - useful for mask calculation in key hashing
assign log_2_num_workers_in=0;

///////////Registers/////////////////////
reg [ADDRESS_WIDTH-1:0] wr_control_write_base_next;          
reg [ADDRESS_WIDTH-1:0] wr_control_write_length_next;        
reg  			wr_control_go_next;
reg 			wr_user_write_buffer_next;                                
reg 			accumulate_fifo_read_slave_read_next;
reg [30:0] 		rd_control_read_base_next;
reg [30:0] 		rd_control_read_length_next;
reg        		rd_control_go_next;
reg	   		rd_user_read_buffer_next;

reg 			accum_type, accum_type_next;
reg 			accumulator_local_read_next;

//Read interface to read from accumulator FIFO
wire  [63: 0] 		accumulate_fifo_read_slave_readdata;
wire 	      		accumulate_fifo_read_slave_waitrequest;
reg           		accumulate_fifo_read_slave_read;
wire [63:0] 		accumulator_local_readdata;
reg         		accumulator_local_read;

reg [log2(NUM_STATES)-1:0] 	state, state_next;
reg [31:0] 		key, message, key_next, message_next;
reg [255:0] 		wr_user_buffer_data_next;
reg [255:0] 		read_data, read_data_next;
wire overflow;
wire [31:0] accumulated_delta_val;
reg [31:0] delta_val, delta_val_next; 

reg end_ext_accumulate_next;
//reg end_local_accumulate_next;
//address
wire [ADDRESS_WIDTH-1:0] key_ddr_addr;

//total links we have accumulated so far
reg [31:0] links_processed_next;
reg [31:0] ext_update_count, ext_update_count_next;

localparam LOCAL=0; //local update
localparam EXT=1; //external update
localparam DELTA_VAL_OFFSET_FROM_RECORD_BASE=8; //Record is organized as [key (offset=0), val(offset=4), delta_val(offset=8), pri, pointer, size, 0, 0]

assign wr_control_fixed_location=1'b0;
assign rd_control_fixed_location=1'b0;
assign accumulate_key = key;

assign key_ddr_addr = DDR_BASE+(key<<5);
//delta val = deltaval + message

///////////key to ddr hashing for multinode clusters
wire [31:0] 		 key_to_ddr_mask;
//assign key_to_ddr_mask = {{32{1'b1}}<<log_2_num_workers_in};

 function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2


float_add_sub float_add_sub(
        .clock	(clk),
	.clk_en (1'b1),
        .dataa	(delta_val),
        .datab	(message),
        .overflow(overflow),
        .result (accumulated_delta_val)
);


always@(*)
begin
	accumulate_fifo_read_slave_read_next = 1'b0;
	key_next = key;
	message_next = message;
	wr_control_write_length_next = wr_control_write_length;
	wr_control_write_base_next = wr_control_write_base;
	wr_control_go_next = 1'b0;
	wr_user_write_buffer_next = 1'b0;
	state_next = state;
	accum_type_next = accum_type;
	accumulator_local_read_next = 1'b0;

	rd_control_read_base_next = rd_control_read_base;
	rd_control_read_length_next = rd_control_read_length;
	rd_control_go_next = 1'b0;
	rd_user_read_buffer_next = 1'b0;
	wr_user_buffer_data_next = wr_user_buffer_data;

	//locking variables
	//end_local_accumulate_next = 1'b0;
	end_ext_accumulate_next = 1'b0;
	links_processed_next = links_processed;
	ext_update_count_next = ext_update_count;
	read_data_next = read_data;
	delta_val_next = delta_val;

	case(state)
		STATE_IDLE: begin
			links_processed_next = 0;
			ext_update_count_next = 0;
			if(do_local_accumulate) begin	
			//if(!accumulator_local_empty) begin	
				state_next = STATE_START_LOCAL_ACCUMULATE;
			end
			else if(do_ext_accumulate) begin
				state_next = STATE_START_EXT_ACCUMULATE;
			end
		end

		STATE_START_LOCAL_ACCUMULATE: begin
			if(!accumulator_local_empty) begin
				//links_processed_next = links_processed+1;
				state_next = STATE_WAIT_READ;
				accumulator_local_read_next = 1'b1;
				accum_type_next = LOCAL;
			end
			else if(end_local_accumulate) begin
				state_next = STATE_IDLE;
			end
			else
				state_next = STATE_START_LOCAL_ACCUMULATE;
		end

		STATE_START_EXT_ACCUMULATE: begin
				if(ext_update_count==MAX_EXT_UPDATES) begin //WE HAVE SERVICED MAX NUMBER OF EXT UPDATES
					end_ext_accumulate_next = 1'b1;
					state_next = STATE_FINISH_ACCUMULATE;
				end
				else if(!accumulate_fifo_read_slave_waitrequest) begin //if fifo is not empty, start reading first key
					ext_update_count_next = ext_update_count+1;
					state_next = STATE_WAIT_READ;
					accumulate_fifo_read_slave_read_next = 1'b1;
					accum_type_next = EXT;
				end
				else begin //FIFO IS EMPTY AND WE HAVENT RECEIVED ANY UPDATES YET
					end_ext_accumulate_next = 1'b1;
					state_next = STATE_FINISH_ACCUMULATE;
				end
		end
		
		STATE_WAIT_READ: begin
			state_next = STATE_READ_KEY_VAL;
		end

		STATE_READ_KEY_VAL: begin
			if(accum_type==EXT) begin
				key_next = accumulate_fifo_read_slave_readdata[63:32];
				message_next = accumulate_fifo_read_slave_readdata[31:0];
			end
			else begin
				key_next = accumulator_local_readdata[63:32];
				message_next = accumulator_local_readdata[31:0];
			end

			state_next = STATE_READ_DELTA_VAL;
		end

		STATE_READ_DELTA_VAL: begin
			//rd_control_read_base_next = DDR_BASE+(key<<5);
			rd_control_read_base_next = DDR_BASE+((key>>log_2_num_workers_in)<<5);
			rd_control_read_length_next = 32;
			rd_control_go_next = 1'b1;
			state_next = STATE_WAIT_DELTA_VAL;
		end

		STATE_WAIT_DELTA_VAL: begin //
			//if(rd_control_done&&rd_user_data_available) begin //deepak - debug:latchup
			if(rd_user_data_available) begin //deepak - debug:latchup
				rd_user_read_buffer_next = 1'b1;
				state_next = STATE_READ_WAIT_CYCLE;
			end
		end

		STATE_READ_WAIT_CYCLE: begin
			read_data_next = rd_user_buffer_data;
			delta_val_next = rd_user_buffer_data[95:64]; //extract delta v
			state_next = STATE_ACCUMULATE;
		end

		STATE_ACCUMULATE: begin
			state_next = WAIT_ADD_1;
		end

		//7 cycles for wait latency (floating point addition)
		WAIT_ADD_1:	state_next = WAIT_ADD_2;
		WAIT_ADD_2:	state_next = WAIT_ADD_3;
		WAIT_ADD_3:	state_next = WAIT_ADD_4;
		WAIT_ADD_4:	state_next = WAIT_ADD_5;
		WAIT_ADD_5:	state_next = WAIT_ADD_6;
		WAIT_ADD_6:	state_next = STATE_UPDATE_DRAM;

		STATE_UPDATE_DRAM: begin
			wr_user_buffer_data_next = {read_data[255:96],accumulated_delta_val,read_data[63:0]}; //
			wr_control_write_base_next = rd_control_read_base;
			wr_control_write_length_next = 32;
			wr_control_go_next = 1'b1;
			state_next = STATE_WRITE_DRAM;
		end

		STATE_WRITE_DRAM: begin
			if(!wr_user_buffer_full) begin
				wr_user_write_buffer_next = 1'b1;
				state_next = STATE_WAIT_DONE;
			end
		end

		STATE_WAIT_DONE: begin
			if(wr_control_done) begin
				links_processed_next = (accum_type==LOCAL)?(links_processed+1):links_processed;
				state_next = (accum_type==LOCAL)?STATE_START_LOCAL_ACCUMULATE:STATE_START_EXT_ACCUMULATE;
			end
		end

		STATE_FINISH_ACCUMULATE:begin
			state_next = STATE_IDLE;
		end
	endcase
end

always@(posedge clk or posedge reset)
begin
	if(reset) begin
		state <= STATE_IDLE;
		accumulate_fifo_read_slave_read <= 1'b0;
		key <= 0;
		message <= 0;
		wr_control_write_length <= 0;
		wr_control_write_base <= 0;
		wr_control_go <= 0;
		wr_user_write_buffer <= 1'b0;
		accum_type <= 0;
		accumulator_local_read <= 0;
		wr_user_buffer_data <= 0;
		rd_control_read_base <= 0;
		rd_control_read_length <= 0;
	   	rd_control_go <= 1'b0;
      		rd_user_read_buffer <= 0;
		delta_val <= 0;
		links_processed <= 0;
		ext_update_count <= 0;
		//end_local_accumulate <= 0;
		end_ext_accumulate <= 0;
		read_data <= 0;
	end 
	else begin
		state <= state_next;
		accumulate_fifo_read_slave_read <= accumulate_fifo_read_slave_read_next;
		key <= key_next;
		message <= message_next;
		wr_control_write_length <= wr_control_write_length_next;
		wr_control_write_base <= wr_control_write_base_next;
		wr_control_go <= wr_control_go_next;
		wr_user_write_buffer <= wr_user_write_buffer_next;
		accum_type <= accum_type_next;
		accumulator_local_read <= accumulator_local_read_next;
		wr_user_buffer_data <= wr_user_buffer_data_next;
		rd_control_read_base <= rd_control_read_base_next;
		rd_control_read_length <= rd_control_read_length_next;
	   	rd_control_go <= rd_control_go_next;
      		rd_user_read_buffer <= rd_user_read_buffer_next;
		delta_val <= delta_val_next;
		links_processed <= links_processed_next;
		ext_update_count <= ext_update_count_next;
		//end_local_accumulate <= end_local_accumulate_next;
		end_ext_accumulate <= end_ext_accumulate_next;
		read_data <= read_data_next;
	end
end

//Local accumulator FIFO (Receives local updates from compute unit)
txfifo #(
        .DATA_WIDTH(64),
//        .LOCAL_FIFO_DEPTH(4096)
	.LOCAL_FIFO_DEPTH(512)

)accumulator_local_fifo (
        .clock          (clk),
        .aclr           (reset),
        .data           (accumulator_local_writedata),
        .rdreq          (accumulator_local_read),
        .wrreq          (accumulator_local_wrreq),
        .q              (accumulator_local_readdata),
        .empty          (accumulator_local_empty),
        .full           (accumulator_local_full),
        .usedw          (),
        .almost_full    ()
);

//External accumulator FIFO (receives external updates from netfpga pipeline)
txfifo #(
        .DATA_WIDTH(64),
        .LOCAL_FIFO_DEPTH(4096)

)accumulate_ext_fifo (
        .clock          (clk),
        .aclr           (reset),
        .data           (accumulate_buffer_writedata),
        .rdreq          (accumulate_fifo_read_slave_read),
        .wrreq          (accumulate_buffer_slave_write),
        .q              (accumulate_fifo_read_slave_readdata),
        .empty          (accumulate_fifo_read_slave_waitrequest),
        .full           (accumulate_buffer_waitrequest),
        .usedw          (),
        .almost_full    ()
);

endmodule


