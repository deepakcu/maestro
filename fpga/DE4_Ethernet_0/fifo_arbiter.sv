`timescale 1ns/1ps


//Mux demux between compute unit fifos and worker fifos
module fifo_arbiter #(
	parameter MAX_NUM_PROCS=8,
	parameter DATA_WIDTH=32,
	parameter WORKER_FIFO_DEPTH=8,
	parameter MAX_NUM_WORKERS=4
   )(
   clk,
   reset,

   ext_fifo_q,
   ext_fifo_empty,
   ext_fifo_rdreq,   

   //interface for external accumulation
   tx_ext_update_data,
   tx_ext_update_wrreq,
   tx_ext_update_full,

   max_fpga_procs,
   log_2_num_workers_in
   
);

//localparam MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE = 32'h3727c5ac; //represents the floting point value for 0.00001 (see gregstoll.dyndns.org/~gregstoll/floattohex for info
localparam MIN_THRESHOLD_TO_SEND_VALUE_OUTSIDE = 32'h38d1b717; //represents the floting point value for 0.0001
localparam NUM_STATES 		= 4;
localparam IDLE 		= 0;
localparam READ_KEYVAL 		= 1;
localparam FINISH_READ 		= 2;
localparam WRITE_KEYVAL 	= 3;

function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
endfunction // log2

/************Parameters******************/
localparam FIFO_DATA_WIDTH=DATA_WIDTH*2;

input clk;
input reset;

//PE fifo inputs
input [FIFO_DATA_WIDTH-1:0] 	ext_fifo_q[MAX_NUM_PROCS-1:0];
input 	 			ext_fifo_empty[MAX_NUM_PROCS-1:0];
output 	  			ext_fifo_rdreq[MAX_NUM_PROCS-1:0];

//Signals for local accumulation

//Signals for external accumulation
output wire [63:0] 				tx_ext_update_data;
output reg [MAX_NUM_WORKERS-1:0] 		tx_ext_update_wrreq; 
reg [MAX_NUM_WORKERS-1:0] 		tx_ext_update_wrreq_next;
input [MAX_NUM_WORKERS-1:0]       		tx_ext_update_full;
input [3:0]					max_fpga_procs;
input [31:0]   log_2_num_workers_in;

/***************Wires********************/
wire [log2(MAX_NUM_PROCS)-1:0] cur_queue_plus1;
reg [log2(MAX_NUM_PROCS)-1:0]  cur_queue;
reg [log2(MAX_NUM_PROCS)-1:0]  cur_queue_next;

reg [NUM_STATES-1:0]        	state;
reg [NUM_STATES-1:0]        	state_next;

reg [MAX_NUM_PROCS-1:0]		ext_fifo_rdreq_internal, ext_fifo_rdreq_internal_next;
reg [DATA_WIDTH-1:0] 		key, key_next;
reg [DATA_WIDTH-1:0] 		val, val_next;

wire [log2(MAX_NUM_WORKERS)-1:0] tgt_fifo;


wire [31:0] mask;
assign mask = ~({32{1'b1}}<<log_2_num_workers_in);
assign tgt_fifo=key&mask;

genvar i;
generate
	for(i=0;i<MAX_NUM_PROCS;i=i+1) begin: as
		assign ext_fifo_rdreq[i] = ext_fifo_rdreq_internal[i];
	end
endgenerate

 /* disable regs for this module */
 //assign cur_queue_plus1    = (cur_queue == MAX_NUM_PROCS-1) ? 0 : (cur_queue + 1); //Always output to queue 1 if using flush ddr mode

 assign cur_queue_plus1    = (cur_queue == max_fpga_procs-1) ? 0 : (cur_queue + 1); //Always output to queue 1 if using flush ddr mode

 assign tx_ext_update_data = {key,val};

   always @(*) begin
	state_next    	= state;
	cur_queue_next	= cur_queue;
	ext_fifo_rdreq_internal_next	= 0;
	key_next 	= key;
	val_next 	= val;
	tx_ext_update_wrreq_next = 0;
      
	case(state)

        /* cycle between input queues  */
        IDLE: begin
           if(!ext_fifo_empty[cur_queue]) begin
              state_next = READ_KEYVAL;
              ext_fifo_rdreq_internal_next[cur_queue] = 1;
           end
	   else begin 
           	cur_queue_next = cur_queue_plus1;
	   end
        end

	READ_KEYVAL: begin
		state_next = FINISH_READ;
	end
	
	FINISH_READ: begin
		key_next = ext_fifo_q[cur_queue][FIFO_DATA_WIDTH-1:DATA_WIDTH];
		val_next = ext_fifo_q[cur_queue][DATA_WIDTH-1:0]; 	
		state_next = WRITE_KEYVAL;
	end

	WRITE_KEYVAL: begin
		if(!tx_ext_update_full[tgt_fifo]) begin
			tx_ext_update_wrreq_next[tgt_fifo] = 1'b1;
			cur_queue_next = cur_queue_plus1;
			state_next = IDLE;
		end
	end	


	default: begin
		state_next = IDLE;
	end
      endcase // case(state)
   end // always @ (*)
   
   always @(posedge clk) begin
      if(reset) begin
         state 			<= IDLE;
         cur_queue 		<= 0;
         ext_fifo_rdreq_internal 	<= 0;
	 tx_ext_update_wrreq<= 0;
	 key 			<= 0;
	 val 			<= 0;
      end
      else begin
         state 			<= state_next;
         cur_queue 		<= cur_queue_next;
         ext_fifo_rdreq_internal 	<= ext_fifo_rdreq_internal_next;
	 tx_ext_update_wrreq<= tx_ext_update_wrreq_next; 
	 key 			<= key_next;
	 val 			<= val_next;
      end
   end

endmodule // input_arbiter


