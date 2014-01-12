
`timescale 1ns/1ps

//Reads from accumulate buffer and writes directly to indexed location in DRAM
module data_loader #(
	parameter DRAM_BASE_ADDR=31'h40000000,
	parameter ADDRESS_WIDTH=31,
	parameter DATA_WIDTH=32,
	parameter BLOCK_SIZE=64
) (

	clk,
	reset,

	//Accumulator port for external writes	
	accumulate_fifo_read_slave_readdata,
	accumulate_fifo_read_slave_waitrequest,
	accumulate_fifo_read_slave_read,

	//Accumulator for internal writes
	accumulator_local_readdata,
	accumulator_local_read,
	accumulator_local_waitrequest,

	//Write interface to write into DDR memory
	control_fixed_location,
        control_write_base,
        control_write_length,    
        control_go,              
        control_done,            
	
	//user logic	
	user_write_buffer,       
        user_buffer_input_data,  
        user_buffer_full
);

localparam NUM_STATES=6;

localparam STATE_IDLE=0;
localparam STATE_WAIT_READ=1;
localparam STATE_READ_KEY_VAL=2;
localparam STATE_COMPUTE_ADDRESS=3;
localparam STATE_WRITE_DRAM=4;
localparam STATE_WAIT_DONE=5;

////////////Ports///////////////////
input clk;
input reset;

//Read interface to read from accumulator FIFO
input  [63: 0] accumulate_fifo_read_slave_readdata;
input 		accumulate_fifo_read_slave_waitrequest;
output reg      accumulate_fifo_read_slave_read;

//Accumulator for local writes
//Signals for local accumulation
input [63:0] accumulator_local_readdata;
input        accumulator_local_waitrequest;
output reg   accumulator_local_read;

// control inputs and outputs
output wire control_fixed_location;
output reg [ADDRESS_WIDTH-1:0] control_write_base;          
output reg [ADDRESS_WIDTH-1:0] control_write_length;        
output reg control_go;
input wire control_done;

// user logic inputs and outputs
output reg user_write_buffer;                                
output reg [DATA_WIDTH-1:0] user_buffer_input_data;          
input wire user_buffer_full;                           

///////////Registers/////////////////////
reg avalonmm_read_slave_read_next;
reg [ADDRESS_WIDTH-1:0] control_write_base_next;          
reg [ADDRESS_WIDTH-1:0] control_write_length_next;        
reg  control_go_next;
reg user_write_buffer_next;                                
reg [DATA_WIDTH-1:0] user_buffer_input_data_next;          
reg [NUM_STATES-1:0] state, state_next;
reg [DATA_WIDTH-1:0] key, val, key_next, val_next;
reg accumulate_fifo_read_slave_read_next;

reg accum_type, accum_type_next;
reg accumulator_local_read_next;

localparam LOCAL=0; //local update
localparam EXT=1; //external update

assign control_fixed_location=1'b0;

always@(*)
begin
	accumulate_fifo_read_slave_read_next = 1'b0;
	key_next = key;
	val_next = val;
	control_write_length_next = control_write_length;
	control_write_base_next = control_write_base;
	control_go_next = 1'b0;
	user_buffer_input_data_next = user_buffer_input_data;
	user_write_buffer_next = 1'b0;
	state_next = state;
	accum_type_next = accum_type;
	accumulator_local_read_next = 1'b0;

	case(state)
		STATE_IDLE: begin
			if(!accumulate_fifo_read_slave_waitrequest) begin //if fifo is not empty, start reading first key
				state_next = STATE_WAIT_READ;
				accumulate_fifo_read_slave_read_next = 1'b1;
				accum_type_next = EXT;
			end
			else if(!accumulator_local_waitrequest) begin
				state_next = STATE_WAIT_READ;
				accumulator_local_read_next = 1'b1;
				accum_type_next = LOCAL;
			end
			else begin
				state_next = STATE_IDLE;
			end
		end

		
		STATE_WAIT_READ: begin
			//Issue a sucessive read to get value (The FIFO must have (key,value) pairs
			accumulate_fifo_read_slave_read_next = 1'b0;
			accumulator_local_read_next = 1'b0;
			state_next = STATE_READ_KEY_VAL;
		end

		STATE_READ_KEY_VAL: begin
			if(accum_type==EXT) begin
				key_next = accumulate_fifo_read_slave_readdata[63:32];
				val_next = accumulate_fifo_read_slave_readdata[31:0];
			end
			else begin
				key_next = accumulator_local_readdata[63:32];
				val_next = accumulator_local_readdata[31:0];
			end

			state_next = STATE_COMPUTE_ADDRESS;
		end

		STATE_COMPUTE_ADDRESS: begin
			control_write_base_next = (DRAM_BASE_ADDR+(key<<BLOCK_SIZE)); //convert key to an addressable location in DDDR2 DRAM [loc=key*64]
			control_write_length_next = 4; //write a 32 bit key
			control_go_next = 1'b1;
			state_next = STATE_WRITE_DRAM;
		end

		STATE_WRITE_DRAM: begin
			if(!user_buffer_full) begin
				user_buffer_input_data_next = val;
				user_write_buffer_next = 1'b1;
				state_next = STATE_WAIT_DONE;
			end
		end

		STATE_WAIT_DONE: begin
			if(control_done)
				state_next = STATE_IDLE;
		end
	endcase
end

always@(posedge clk)
begin
	if(reset) begin
		state <= STATE_IDLE;
		accumulate_fifo_read_slave_read <= 1'b0;
		key <= 0;
		val <= 0;
		control_write_length <= 0;
		control_write_base <= 0;
		control_go <= 0;
		user_buffer_input_data <= 0;
		user_write_buffer <= 1'b0;
		accum_type <= 0;
		accumulator_local_read <= 0;
	end 
	else begin
		state <= state_next;
		accumulate_fifo_read_slave_read <= accumulate_fifo_read_slave_read_next;
		key <= key_next;
		val <= val_next;
		control_write_length <= control_write_length_next;
		control_write_base <= control_write_base_next;
		control_go <= control_go_next;
		user_buffer_input_data <= user_buffer_input_data_next;
		user_write_buffer <= user_write_buffer_next;
		accum_type <= accum_type_next;
		accumulator_local_read <= accumulator_local_read_next;
	end
end
endmodule


