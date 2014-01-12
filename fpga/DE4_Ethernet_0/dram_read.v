
`timescale 1ns/1ps

//Reads from accumulate buffer and writes directly to indexed location in DRAM
module dram_read #(
	parameter DDR_BASE=31'h00000000,
	parameter ADDRESS_WIDTH=31,
	parameter TOTAL_DATA=8
) (

	clk,
	reset,
	
	//External writes to dram
	dram_fifo_readdata,
	dram_fifo_read,
	dram_fifo_empty,

	//Write interface to write into DDR memory
	control_fixed_location,
	control_read_base,
        control_read_length,    
        control_go,              
        control_done,            

	user_read_buffer,       
        user_buffer_output_data,  
	user_data_available,

	dram_flush,	//the op_lut_process module will assert this signal, following which dram contents will be available in the fifo
	num_keys
);




localparam NUM_STATES=5;

localparam STATE_IDLE=1;
localparam STATE_START_FLUSH=2;
localparam STATE_WAIT_READ=4;
localparam STATE_READ_DATA=8;
localparam STATE_WRITE_FIFO=16;
////////////Ports///////////////////
input clk;
input reset;

//Interface for external writes//
output [63:0] 		dram_fifo_readdata;
input        		dram_fifo_read;
output       		dram_fifo_empty;


// Write control inputs and outputs
output wire 		control_fixed_location;
output reg [ADDRESS_WIDTH-1:0] 	control_read_base;          
output wire [ADDRESS_WIDTH-1:0] 	control_read_length;        
output reg 		control_go;
input wire 		control_done;

// Write user logic inputs and outputs
output reg 		user_read_buffer;                                
input wire [255:0] 	user_buffer_output_data;          
input wire 		user_data_available;                           

input dram_flush;
input [31:0] num_keys;
///////////Registers/////////////////////
reg [ADDRESS_WIDTH-1:0] control_read_base_next;          
reg [ADDRESS_WIDTH-1:0] control_read_length_next;        
reg  			control_go_next;
reg 			user_read_buffer_next;                                

reg [NUM_STATES-1:0] 	state, state_next;
reg [31:0]		counter,counter_next;
reg [63:0]		dram_wr_val, dram_wr_val_next;
assign control_fixed_location=1'b0;
assign control_read_length = 32;
wire dram_fifo_full;
reg dram_fifo_write, dram_fifo_write_next;

always@(*)
begin
	dram_fifo_write_next = 1'b0;
	control_read_base_next = control_read_base;
	control_go_next = 1'b0;
	user_read_buffer_next = 1'b0;
	state_next = state;
	counter_next = counter;
	dram_wr_val_next = dram_wr_val;

	case(state)
		STATE_IDLE: begin
			if(dram_flush) begin //if fifo is not empty, start reading first key
				counter_next = 0;
				state_next = STATE_START_FLUSH;
			end
		end

		STATE_START_FLUSH: begin
        		control_read_base_next = DDR_BASE+(counter<<5);
        		control_go_next = 1'b1;
			state_next = STATE_WAIT_READ;
		end
			
		STATE_WAIT_READ: begin
			if(user_data_available) begin
				state_next = STATE_READ_DATA;
				user_read_buffer_next = 1'b1;
			end
		end
	
		STATE_READ_DATA: begin
			dram_wr_val_next = {user_buffer_output_data[31:0],user_buffer_output_data[63:32]}; //write 64 bits [key and value]
			counter_next = counter+1;
			state_next = STATE_WRITE_FIFO;
		end

		STATE_WRITE_FIFO: begin
			if(!dram_fifo_full) begin
				dram_fifo_write_next = 1'b1;
				//state_next = (counter==TOTAL_DATA)?STATE_IDLE:STATE_START_FLUSH;
				state_next = (counter==num_keys)?STATE_IDLE:STATE_START_FLUSH;
			end
		end
	endcase
end

always@(posedge clk or posedge reset)
begin
	if(reset) begin
		state <= STATE_IDLE;
		dram_fifo_write <= 1'b0;
		control_read_base <= 0;
		control_go <= 0;
		user_read_buffer <= 1'b0;
		counter <= 0;
		dram_wr_val <= 0;
	end 
	else begin
		state <= state_next;
		dram_fifo_write <= dram_fifo_write_next;
		control_read_base <= control_read_base_next;
		control_go <= control_go_next;
		user_read_buffer <= user_read_buffer_next;
		counter <= counter_next;
		dram_wr_val <= dram_wr_val_next;
	end
end


//External accumulator FIFO (receives external updates from netfpga pipeline)
txfifo #(
        .DATA_WIDTH(64),
        .LOCAL_FIFO_DEPTH(32)

)fifo (
        .clock          (clk),
        .aclr           (reset),
        .data           (dram_wr_val), //write key and value
        .rdreq          (dram_fifo_read),
        .wrreq          (dram_fifo_write),
        .q              (dram_fifo_readdata),
        .empty          (dram_fifo_empty),
        .full           (dram_fifo_full),
        .usedw          (),
        .almost_full    ()
);

endmodule


