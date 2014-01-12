
///////Courtsey: design from asic-world.com////////////
//-----------------------------------------------------
// Design Name : lfsr
// File Name   : lfsr.v
// Function    : Linear feedback shift register
// Coder       : Deepak Kumar Tala
// Modified by : Deepak Unnikrishnan, UMass Amherst
//-----------------------------------------------------
module lfsr #(
	parameter ADDR_WIDTH=8,
	parameter MAX_ADDR_VAL=256
) (
   num_keys,
   lfsr_out, 
   lfsr_start,
   enable, 
   clk,   
   reset 
);

//----------Output Ports--------------
//output wire [ADDR_WIDTH-1:0] lfsr_out;
output wire [31:0] lfsr_out;
//output reg [ADDR_WIDTH-1:0] lfsr_start; 
output reg [31:0] lfsr_start; 
//wire [ADDR_WIDTH-1:0] lfsr_start_next;
wire [31:0] lfsr_start_next;
//------------Input Ports--------------
input [31:0] num_keys;
input enable, clk, reset;
//------------Internal Variables--------
//reg [ADDR_WIDTH-1:0] out;
reg [31:0] out;
wire        linear_feedback;
//wire [ADDR_WIDTH-1:0] out_shifted;
wire [31:0] out_shifted;

reg state, state_next;
reg [5:0] select;
wire [31:0] mask;
localparam NORMAL=0;
localparam PAUSE=1;
//assign lfsr_out = (state==NORMAL)?out:{ADDR_WIDTH{1'b1}};
assign lfsr_out = (state==NORMAL)?(out&mask):32'b1;
assign lfsr_start_next = lfsr_start;
assign mask = ~(~0<<select);
//-------------Code Starts Here-------
//---Define Linear Feedback polynomial here
	/*
	assign linear_feedback = 
	(ADDR_WIDTH==2) ? !(out[1] ^ out[0]): //1+x+x2
	(ADDR_WIDTH==3) ? !(out[2] ^ out[1]): //1+x2+x3
	(ADDR_WIDTH==4) ? !(out[3] ^ out[2]): //1+x3+x4
	(ADDR_WIDTH==5) ? !(out[4] ^ out[2]): //1+x3+x5
	(ADDR_WIDTH==6) ? !(out[5] ^ out[4]): //1+x5+x6
	(ADDR_WIDTH==7) ? !(out[6] ^ out[5]): //1+x6+x7
	(ADDR_WIDTH==8) ? !(out[7] ^ out[5] ^ out[4] ^ out[3]): //1+x4+x5+x6+x8
	(ADDR_WIDTH==9) ? !(out[8] ^ out[4]): //1+x5+x9
	(ADDR_WIDTH==10) ? !(out[9] ^ out[6]): //1+x7+x10
	(ADDR_WIDTH==11) ? !(out[8] ^ out[10]): //1+x9+x11
	(ADDR_WIDTH==12) ? !(out[11] ^ out[10] ^ out[9] ^ out[3]): //x12+x11+x10+x4+1
	(ADDR_WIDTH==13) ? !(out[12] ^ out[11] ^ out[10] ^ out[7]): //x13+x12+x11+x8+1
	(ADDR_WIDTH==14) ? !(out[13] ^ out[12] ^ out[11] ^ out[1]): //x14+x13+x12+x2+1
	(ADDR_WIDTH==15) ? !(out[14] ^ out[13]): //x15+x14+1
	(ADDR_WIDTH==16) ? !(out[15] ^ out[13] ^ out[12] ^ out[10]): //x16+x14+x13+x11+1
	(ADDR_WIDTH==17) ? !(out[16] ^ out[13]): //x17+x14+1
	(ADDR_WIDTH==18) ? !(out[17] ^ out[10]): //x18+x11+1
	(ADDR_WIDTH==19) ? !(out[18] ^ out[17] ^ out[16] ^ out[13]): //x19+x18+x17+x14+1
	(ADDR_WIDTH==20) ? !(out[19] ^ out[16]): //x20+x17+1
	!(out[0] ^ out[1]);
	*/


	assign linear_feedback = 
	(select==2) ? !(out[1] ^ out[0]): //1+x+x2
	(select==3) ? !(out[2] ^ out[1]): //1+x2+x3
	(select==4) ? !(out[3] ^ out[2]): //1+x3+x4
	(select==5) ? !(out[4] ^ out[2]): //1+x3+x5
	(select==6) ? !(out[5] ^ out[4]): //1+x5+x6
	(select==7) ? !(out[6] ^ out[5]): //1+x6+x7
	(select==8) ? !(out[7] ^ out[5] ^ out[4] ^ out[3]): //1+x4+x5+x6+x8
	(select==9) ? !(out[8] ^ out[4]): //1+x5+x9
	(select==10) ? !(out[9] ^ out[6]): //1+x7+x10
	(select==11) ? !(out[8] ^ out[10]): //1+x9+x11
	(select==12) ? !(out[11] ^ out[10] ^ out[9] ^ out[3]): //x12+x11+x10+x4+1
	(select==13) ? !(out[12] ^ out[11] ^ out[10] ^ out[7]): //x13+x12+x11+x8+1
	(select==14) ? !(out[13] ^ out[12] ^ out[11] ^ out[1]): //x14+x13+x12+x2+1
	(select==15) ? !(out[14] ^ out[13]): //x15+x14+1
	(select==16) ? !(out[15] ^ out[13] ^ out[12] ^ out[10]): //x16+x14+x13+x11+1
	(select==17) ? !(out[16] ^ out[13]): //x17+x14+1
	(select==18) ? !(out[17] ^ out[10]): //x18+x11+1
	(select==19) ? !(out[18] ^ out[17] ^ out[16] ^ out[13]): //x19+x18+x17+x14+1
	(select==20) ? !(out[19] ^ out[16]): //x20+x17+1
	(select==21) ? !(out[20] ^ out[18]): //x21+x19
	(select==22) ? !(out[21] ^ out[20]): //x22+x21
	(select==23) ? !(out[22] ^ out[17]): //x23+x18
	!(out[0] ^ out[1]);


//use a priority encoder to choose the LFSR feedback selection
always@(*)
begin
	casex(num_keys)
		32'b1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: select = 32;
		32'b01xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: select = 31;
		32'b001xxxxxxxxxxxxxxxxxxxxxxxxxxxxx: select = 30;
		32'b0001xxxxxxxxxxxxxxxxxxxxxxxxxxxx: select = 29;
		32'b00001xxxxxxxxxxxxxxxxxxxxxxxxxxx: select = 28;
		32'b000001xxxxxxxxxxxxxxxxxxxxxxxxxx: select = 27;
		32'b0000001xxxxxxxxxxxxxxxxxxxxxxxxx: select = 26;
		32'b00000001xxxxxxxxxxxxxxxxxxxxxxxx: select = 25;
		32'b000000001xxxxxxxxxxxxxxxxxxxxxxx: select = 24;
		32'b0000000001xxxxxxxxxxxxxxxxxxxxxx: select = 23;
		32'b00000000001xxxxxxxxxxxxxxxxxxxxx: select = 22;
		32'b000000000001xxxxxxxxxxxxxxxxxxxx: select = 21;
		32'b0000000000001xxxxxxxxxxxxxxxxxxx: select = 20;
		32'b00000000000001xxxxxxxxxxxxxxxxxx: select = 19;
		32'b000000000000001xxxxxxxxxxxxxxxxx: select = 18;
		32'b0000000000000001xxxxxxxxxxxxxxxx: select = 17;
		32'b00000000000000001xxxxxxxxxxxxxxx: select = 16;
		32'b000000000000000001xxxxxxxxxxxxxx: select = 15;
		32'b0000000000000000001xxxxxxxxxxxxx: select = 14;
		32'b00000000000000000001xxxxxxxxxxxx: select = 13;
		32'b000000000000000000001xxxxxxxxxxx: select = 12;
		32'b0000000000000000000001xxxxxxxxxx: select = 11;
		32'b00000000000000000000001xxxxxxxxx: select = 10;
		32'b000000000000000000000001xxxxxxxx: select = 9;
		32'b0000000000000000000000001xxxxxxx: select = 8;
		32'b00000000000000000000000001xxxxxx: select = 7;
		32'b000000000000000000000000001xxxxx: select = 6;
		32'b0000000000000000000000000001xxxx: select = 5;
		32'b00000000000000000000000000001xxx: select = 4;
		32'b000000000000000000000000000001xx: select = 3;
		32'b0000000000000000000000000000001x: select = 2;
		32'b00000000000000000000000000000001: select = 1;
		default: select = 0;
	endcase
end


//(ADDR_WIDTH==2) ? !(out[7] ^ out[3]):
genvar i;
generate
for(i=0;i<32;i=i+1) begin: lfeedback
	if(i==0)
		assign out_shifted[i] = linear_feedback;  
	else
		assign out_shifted[i] = out[i-1];  
end
endgenerate


always @(posedge clk or posedge reset)
if (reset) begin // active high reset
  out <= 0 ;
end else if (enable && state==NORMAL) begin
  out <= out_shifted;
end 

always@(*) begin
	state_next = state;
	case(state) 
		NORMAL: begin 
			if(out_shifted==0)
				state_next = (enable)?PAUSE:NORMAL;
		end
	
		PAUSE: begin
			state_next = (enable)?NORMAL:PAUSE;	
		end
		
		default: state_next = NORMAL;
	endcase
end

always@(posedge clk or posedge reset) begin
if(reset)
	//lfsr_start <= out_shifted[ADDR_WIDTH-1:0]; //Capture the start value of the LFSR registe
	lfsr_start <= out_shifted; //Capture the start value of the LFSR registe
else
	lfsr_start <= lfsr_start_next;	
end

always@(posedge clk or posedge reset) begin
if(reset)
	state <= NORMAL;
else
	state <= state_next;

end
endmodule // End Of Module counter

