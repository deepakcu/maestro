
`timescale 1ns/1ps

module write_release #(
		       parameter DDR_BASE=0,
		       parameter DEFAULT_READ_LENGTH=32,
		       parameter COMPUTE_WRITE_FIFO_WIDTH = 257 //(1+1+32+256)
		       ) (
			  input 			       clk,
			  input 			       reset,

			  input [COMPUTE_WRITE_FIFO_WIDTH-1:0] compute_write_fifo_q,
			  input 			       compute_write_fifo_empty,
			  output reg 			       compute_write_fifo_rdreq,

			  //write interface b/w write-release unit and main memory
			  output wire 			       wr_control_fixed_location,
			  output reg [30:0] 		       wr_control_write_base,
			  output reg [30:0] 		       wr_control_write_length,
			  output reg 			       wr_control_go,
			  input wire 			       wr_control_done,

			  output reg 			       wr_user_write_buffer,
			  output reg [255:0] 		       wr_user_buffer_data,
			  input wire 			       wr_user_buffer_full,

			  input [31:0] 			       log_2_num_workers_in,
			  output reg 			       proc_key_release,
			  input 			       proc_key_release_ack
			  );
   
   //log2
   function integer log2;
      input integer 					       number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2
   
   localparam NUM_STATES			=6;
   localparam IDLE				=0;
   localparam READ_FIFO			=1;
   localparam PARSE 			=2;
   localparam FILTER			=3;
   localparam WRITE_UPDATE			=4;
   localparam WRITE_UPDATE_WAIT		=5;
   //localparam WAIT_RELEASE			=6;
   
   //registers and wires
   reg [log2(NUM_STATES)-1:0]	state, state_next;
   reg [30:0] 			wr_control_write_base_next;
   reg [30:0] 			wr_control_write_length_next;
   reg 				wr_control_go_next;
   reg [255:0] 			wr_user_buffer_data_next;
   reg 				wr_user_write_buffer_next;
   
   
   reg 				filter_bit, filter_bit_next;
   reg 				proc_key_release_next;
   reg [255:0] 			write_entry, write_entry_next;
   reg [31:0] 			key, key_next;
   reg 				compute_write_fifo_rdreq_next;
   
   assign wr_control_fixed_location = 0;
   
   reg [31:0] 			filt_entries, filt_entries_next /*synthesis preserve*/;
   
   always@(*)
     begin
	
	state_next = state;
	wr_control_write_base_next = wr_control_write_base;
        wr_control_write_length_next =  wr_control_write_length;
        wr_control_go_next = 1'b0;
        wr_user_write_buffer_next = 1'b0;
        wr_user_buffer_data_next = wr_user_buffer_data;
	proc_key_release_next = 0;
	compute_write_fifo_rdreq_next = 0;
	key_next = key;
	filter_bit_next = filter_bit;
	write_entry_next = write_entry;
	filt_entries_next = filt_entries;	
	
	case(state)
	  IDLE: begin
	     if(!compute_write_fifo_empty) begin
		compute_write_fifo_rdreq_next = 1'b1;
		state_next = READ_FIFO;
	     end			
	  end
	  
	  READ_FIFO:begin
	     state_next = PARSE;
	  end
	  
	  PARSE:begin
	     filter_bit_next 	= compute_write_fifo_q[256];
	     write_entry_next 	= compute_write_fifo_q[255:0];
	     key_next		= compute_write_fifo_q[31:0];
	     state_next 		= FILTER;
	  end
	  
	  FILTER:begin
	     if(filter_bit==1) begin
		filt_entries_next = filt_entries+1;
		proc_key_release_next = 1'b1;
		state_next = IDLE; //WAIT_RELEASE;
	     end
	     else begin
		//ddr addr = hash(key)*32. Hash fn = mod
        	wr_control_write_base_next 	= DDR_BASE+((key>>log_2_num_workers_in)<<5); 
		wr_control_write_length_next 	= DEFAULT_READ_LENGTH;
	        wr_control_go_next 		= 1'b1;
                wr_user_buffer_data_next 	= write_entry;
		state_next 			= WRITE_UPDATE;
	     end
	  end
	  
	  WRITE_UPDATE:begin
	     if(!wr_user_buffer_full) begin
		wr_user_write_buffer_next 	= 1'b1;
		state_next 			= WRITE_UPDATE_WAIT;
	     end		
	  end
	  
	  WRITE_UPDATE_WAIT:begin
	     if(wr_control_done) begin
		proc_key_release_next = 1;
		//				state_next = WAIT_RELEASE;
		state_next = IDLE;
	     end
	  end
	  
	  /*		WAIT_RELEASE: begin
	   if(!proc_key_release_ack) begin
	   proc_key_release_next		= 1;
			end
	   else begin
	   state_next			= IDLE;
			end
		end
	   */
	  default: state_next = IDLE;
	endcase
     end
   
   always@(posedge clk) begin
      if(reset) begin
	 state 		<= IDLE;
	 wr_control_write_base 		<= 0;
         wr_control_write_length 	<= 0;
         wr_control_go 			<= 0;
         wr_user_write_buffer 		<= 0;
         wr_user_buffer_data 		<= 0;
	 proc_key_release 		<= 0;
	 key			<= 0;
	 write_entry	<= 0;
	 filter_bit		<= 0;
	 filt_entries			<= 0;	
      end
      else begin
	 state 				<= state_next;
         wr_control_write_base 		<= wr_control_write_base_next;
	 wr_control_write_length 	<= wr_control_write_length_next;
         wr_control_go 			<= wr_control_go_next;
         wr_user_write_buffer 		<= wr_user_write_buffer_next;
         wr_user_buffer_data 		<= wr_user_buffer_data_next;
	 proc_key_release		<= proc_key_release_next;
	 compute_write_fifo_rdreq	<= compute_write_fifo_rdreq_next;
	 key				<= key_next;
	 write_entry			<= write_entry_next;
	 filter_bit			<= filter_bit_next;
	 filt_entries			<= filt_entries_next;	
      end
   end
endmodule
