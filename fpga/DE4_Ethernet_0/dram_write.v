
`timescale 1ns/1ps

//Reads from accumulate buffer and writes directly to indexed location in DRAM
module dram_write #(
	parameter DDR_BASE=31'h00000000,
	parameter ADDRESS_WIDTH=31
) (

	clk,
	reset,
	
	//External writes to dram
	dram_fifo_writedata,
	dram_fifo_write,
	dram_fifo_full,

	//Write interface to write into DDR memory
	control_fixed_location,
	control_write_base,
        control_write_length,    
        control_go,              
        control_done,            

	user_write_buffer,       
        user_buffer_input_data,  
	user_buffer_full
);
localparam DATA_WIDTH=256;



localparam NUM_STATES=6;

localparam STATE_IDLE		=1;
localparam STATE_WAIT		=2;
localparam STATE_READ		=4;
localparam STATE_CHECK_WORD	=8;
localparam STATE_WRITE_DRAM	=16;
localparam STATE_WAIT_DONE	=32;
////////////Ports///////////////////
input clk;
input reset;

//Interface for external writes//
input [63:0] dram_fifo_writedata;
input        dram_fifo_write;
output       dram_fifo_full;


// Write control inputs and outputs
output wire 		control_fixed_location;
output reg [30:0] 	control_write_base;          
output wire [30:0] 	control_write_length;        
output reg 		control_go;
input wire 		control_done;

// Write user logic inputs and outputs
output reg 		user_write_buffer;                                
output reg [255:0] 	user_buffer_input_data;          
input wire 		user_buffer_full;                           

///////////Registers/////////////////////
reg [ADDRESS_WIDTH-1:0] control_write_base_next;          
reg  			control_go_next;
reg 			user_write_buffer_next;                                
reg [255:0] 		user_buffer_input_data_next;          

reg [NUM_STATES-1:0] 	state, state_next;

reg 			dram_fifo_read, dram_fifo_read_next;
wire [63:0] 		dram_fifo_readdata;
wire 			dram_fifo_empty;
reg 			dram_fifo_write_next;


assign control_fixed_location=1'b0;

wire [255:0] dram_wr_value;
reg [31:0] dram_wr_value_internal[7:0]; 
reg [31:0] dram_wr_value_internal_next[7:0]; 
reg [2:0] offset_from_base, offset_from_base_next;
//reg [2:0] offset_from_base_reg;
genvar i;
generate
        for(i=0;i<8;i=i+1) begin:d
                assign dram_wr_value[(i+1)*32-1:i*32] = dram_wr_value_internal[i];
        end
endgenerate

//Load inputs look the following way
//Addr data
//0	key[0]
//4	val[0]
//8	delta[0]..

//assign offset_from_base = (dram_fifo_readdata[63:32]>>2)&&3'h7; //divide addr by 4 and look at lower 3 bits
/*
always@(*) 
begin
	dram_wr_value_internal_next[0] = dram_wr_value_internal[0];
	dram_wr_value_internal_next[1] = dram_wr_value_internal[1];
	dram_wr_value_internal_next[2] = dram_wr_value_internal[2];
	dram_wr_value_internal_next[3] = dram_wr_value_internal[3];
	dram_wr_value_internal_next[4] = dram_wr_value_internal[4];
	dram_wr_value_internal_next[5] = dram_wr_value_internal[5];
	dram_wr_value_internal_next[6] = dram_wr_value_internal[6];
	dram_wr_value_internal_next[7] = dram_wr_value_internal[7];

	case(offset_from_base) //
		0: dram_wr_value_internal_next[0] = dram_fifo_readdata[31:0];
		1: dram_wr_value_internal_next[1] = dram_fifo_readdata[31:0];
		2: dram_wr_value_internal_next[2] = dram_fifo_readdata[31:0];
		3: dram_wr_value_internal_next[3] = dram_fifo_readdata[31:0];
		4: dram_wr_value_internal_next[4] = dram_fifo_readdata[31:0];
		5: dram_wr_value_internal_next[5] = dram_fifo_readdata[31:0];
		6: dram_wr_value_internal_next[6] = dram_fifo_readdata[31:0];
		7: dram_wr_value_internal_next[7] = dram_fifo_readdata[31:0];
	endcase
end
*/

assign  control_write_length = 32; //write 32 bytes

always@(*)
begin
	dram_fifo_read_next = 1'b0;
	control_write_base_next = control_write_base;
	control_go_next = 1'b0;
	user_write_buffer_next = 1'b0;
	offset_from_base_next = offset_from_base;
	state_next = state;
	user_buffer_input_data_next = user_buffer_input_data;
	
	dram_wr_value_internal_next[0] = dram_wr_value_internal[0];
	dram_wr_value_internal_next[1] = dram_wr_value_internal[1];
	dram_wr_value_internal_next[2] = dram_wr_value_internal[2];
	dram_wr_value_internal_next[3] = dram_wr_value_internal[3];
	dram_wr_value_internal_next[4] = dram_wr_value_internal[4];
	dram_wr_value_internal_next[5] = dram_wr_value_internal[5];
	dram_wr_value_internal_next[6] = dram_wr_value_internal[6];
	dram_wr_value_internal_next[7] = dram_wr_value_internal[7];

	case(state)
		STATE_IDLE: begin
			if(!dram_fifo_empty) begin //if fifo is not empty, start reading first key
				state_next = STATE_WAIT;
				dram_fifo_read_next = 1'b1;
			end
			else begin
				state_next = STATE_IDLE;
			end
		end

		STATE_WAIT: begin //1 cycle wait to read from FIFO
			state_next = STATE_READ;
		end

		STATE_READ: begin
			offset_from_base_next = dram_fifo_readdata[36:34]; //shift right by 2 and look at lower 3 bits if the upper word (ie. 64:32)
			state_next = STATE_CHECK_WORD;
		end

		STATE_CHECK_WORD: begin
			if(offset_from_base==3'h0) begin
				control_write_base_next = DDR_BASE+(dram_fifo_readdata[63:32]); //addr located from 64 to 32
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[0] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h1) begin
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[1] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h2) begin
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[2] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h3) begin
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[3] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h4) begin
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[4] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h5) begin
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[5] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h6) begin
				state_next = STATE_IDLE;
				dram_wr_value_internal_next[6] = dram_fifo_readdata[31:0];
			end
			else if(offset_from_base==3'h7) begin
				state_next = STATE_WRITE_DRAM;
				dram_wr_value_internal_next[7] = dram_fifo_readdata[31:0];
			        control_go_next = 1'b1;
			end
			else
				state_next = STATE_IDLE;
		end

		STATE_WRITE_DRAM: begin
			if(!user_buffer_full) begin
				user_buffer_input_data_next = dram_wr_value;
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
		state 			  <= STATE_IDLE;
		control_write_base 	  <= 0;
		control_go 		  <= 0;
		user_write_buffer 	  <= 1'b0;

		dram_wr_value_internal[0] <= 0;
		dram_wr_value_internal[1] <= 0; //dram_wr_value_internal[1];
		dram_wr_value_internal[2] <= 0; //dram_wr_value_internal[2];
		dram_wr_value_internal[3] <= 0; //dram_wr_value_internal[3];
		dram_wr_value_internal[4] <= 0; //dram_wr_value_internal[4];
		dram_wr_value_internal[5] <= 0; //dram_wr_value_internal[5];
		dram_wr_value_internal[6] <= 0; //dram_wr_value_internal[6];
		dram_wr_value_internal[7] <= 0; //dram_wr_value_internal[7];

		user_buffer_input_data 	  <= 0;
		//test signal
		offset_from_base 	  <= 0;
		dram_fifo_read 		  <= 0;
	end 
	else begin
		state 			  <= state_next;
		control_write_base 	  <= control_write_base_next;
		control_go 		  <= control_go_next;
		user_write_buffer 	  <= user_write_buffer_next;

		dram_wr_value_internal[0] <= dram_wr_value_internal_next[0];
		dram_wr_value_internal[1] <= dram_wr_value_internal_next[1];
		dram_wr_value_internal[2] <= dram_wr_value_internal_next[2];
		dram_wr_value_internal[3] <= dram_wr_value_internal_next[3];
		dram_wr_value_internal[4] <= dram_wr_value_internal_next[4];
		dram_wr_value_internal[5] <= dram_wr_value_internal_next[5];
		dram_wr_value_internal[6] <= dram_wr_value_internal_next[6];
		dram_wr_value_internal[7] <= dram_wr_value_internal_next[7];

		user_buffer_input_data 	  <= user_buffer_input_data_next;
		offset_from_base 	  <= offset_from_base_next;
		dram_fifo_read 		  <= dram_fifo_read_next;
	end
end


//accumulator FIFO (receives external updates from netfpga pipeline)
txfifo #(
        .DATA_WIDTH(64),
        //.LOCAL_FIFO_DEPTH(8192)
        //.LOCAL_FIFO_DEPTH(16384) //increase size suspecting buffer overflow
        .LOCAL_FIFO_DEPTH(2048)

) fifo (
        .clock          (clk),
        .aclr           (reset),
        .data           (dram_fifo_writedata),
        .rdreq          (dram_fifo_read),
        .wrreq          (dram_fifo_write),
        .q              (dram_fifo_readdata),
        .empty          (dram_fifo_empty),
        .full           (dram_fifo_full),
        .usedw          (),
        .almost_full    ()
);

endmodule


