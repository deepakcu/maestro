
`include "command_defines.v"

//Receives a key, value pair from FIFO arbiter.
//Composes a UDP packet and pushes it through the output queues
module packet_composer
  #(parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH = DATA_WIDTH/8,
    parameter NUM_QUEUES = 8,
    parameter NUM_QUEUES_WIDTH = log2(NUM_QUEUES),
    parameter STAGE_NUM  = 4,
    parameter IOQ_STAGE_NUM = 8'hff,
    //parameter MAX_NUM_PROCS=2,
	 parameter WORKER_ADDR_WIDTH=2,
	parameter TOTAL_DATA=8
   )
  (
   
   // --- interface to next module
   output reg                         out_wr,
   output reg [DATA_WIDTH-1:0]        out_data,
   output reg [CTRL_WIDTH-1:0]        out_ctrl,     // new checksum assuming decremented TTL
   input                              out_rdy,

   input [31:0] 		      iteration_accum_value,
   input 			      iteration_terminate_check,

   //read interface from DDR (used by flush data function)
   input [63:0]  dram_fifo_readdata,
   output reg    dram_fifo_read,
   input         dram_fifo_empty,
   input [31:0]  num_keys,

   //i/f b/w TX EXT FIFO and packet composer
   input  [63:0]          tx_ext_update_q,
   output reg             tx_ext_update_rdreq,
   input                  tx_ext_update_empty,
   input		  tx_ext_update_almost_full,

   input [31:0]		  interpkt_gap_cycles,

   // misc
   input reset,
   input clk
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
   
   localparam MAX_NUM_PROCS=2**WORKER_ADDR_WIDTH;
   localparam MAC_ADDR_WIDTH=48;
   localparam IP_ADDR_WIDTH=32;
   reg [31:0] flushed_keys, flushed_keys_next;
   reg dram_fifo_read_next;
	
   //------------------- Internal parameters -----------------------
   //Hardcode IP headers (simplfies our hardware logic)
     
   localparam NUM_STATES           	= 15;
   localparam WAIT_DATA		   	= 0;
   localparam SEND_PUT_NETFPGA_HDR 	= 1;
   localparam SEND_PUT_HDR	   	= 2;
   localparam READ_PUT_WORD		= 3;
   localparam SEND_PUT_PKT         	= 4;
   localparam INTERPKT_GAP		= 5;
   localparam FLUSH_DATA 	    	= 6;
   localparam SEND_FLUSH_NETFPGA_HDR	= 7;
   localparam SEND_FLUSH_HDR	    	= 8;
   localparam READ_DRAM_WORD		= 9;
   localparam SEND_FLUSH_PKT	    	= 10;
   localparam SEND_TCHECK_NETFPGA_HDR	= 11;
   localparam SEND_TCHECK_HDR	   	= 12;
   localparam READ_ACCUMULATE_WORD	= 13;
   localparam SEND_TCHECK_PKT      	= 14;
   

   //---------------------- Wires and regs -------------------------
   
   reg [log2(NUM_STATES)-1:0] state;
   reg [log2(NUM_STATES)-1:0] state_next;
   reg [DATA_WIDTH-1:0] out_data_next;
   reg [CTRL_WIDTH-1:0] out_ctrl_next;
   reg                  out_wr_next;
   reg [31:0]		interpkt_gap_counter, interpkt_gap_counter_next;



   reg accum_value_fifo_rdreq, accum_value_fifo_rdreq_next;
   wire [31:0] accum_value_fifo_dataout;
   wire accum_value_fifo_empty;
   wire accum_value_fifo_full;
   reg [31:0] packet_sent /*synthesis noprune*/;
   wire [31:0] key, val;
   wire [31:0] key_little; //key in little endian format;
   wire [31:0] val_little; //val in little endian format;

   assign key = tx_ext_update_q[63:32];
   assign val = tx_ext_update_q[31:0];
   assign key_little = {key[7:0],key[15:8],key[23:16],key[31:24]};
   assign val_little = {val[7:0],val[15:8],val[23:16],val[31:24]};


   //-------------------------- Logic ------------------------------

   localparam INTERPKT_CLK_CYCLES  = 8000; //try doubling the cycles from 4000 to 8000- as software is still overwhelmed with packet floods
   localparam MAX_WORDS_PER_PACKET = 150; //total data = 150*64 bits/8 bit = 1200bytes
   localparam EXTERNAL_FIFO_DEPTH = 2*MAX_WORDS_PER_PACKET;
   localparam MAX_WORDS_IN_HEADER = 7; //excluding netfpga default header //FOR FLUSH AND TERMCHECK UPDATES
   localparam MAX_WORDS_IN_PUT_HEADER = 6; //ONLY FOR PUT UPDATES

   reg [log2(MAX_WORDS_IN_HEADER)-1:0] word_sel, word_sel_next;

   reg [31:0] words_per_packet_cnt, words_per_packet_cnt_next;	
   reg  tx_ext_update_rdreq_next;// tx_ext_update_rdreq_next;
   wire [63:0] tx_ext_update_dataout;

   `include "headers.v"
   //A small fifo to store the iteration accumulate value
   //
   
   reg [31:0] time_tick;
   reg pkt_wr;

   always@(posedge clk) begin
	if(reset) begin
		time_tick <= 0;
		pkt_wr <= 0;
	end
	else begin
		if(time_tick==125000000) begin
			time_tick <= 0;
			pkt_wr <= 1;
		end
		else begin
			time_tick <= time_tick+1;
			pkt_wr <= 0;
		end
	end
   end
   
   
   txfifo #(
        .DATA_WIDTH(32),
        .LOCAL_FIFO_DEPTH(4)

   ) accum_value_fifo (
        //.aclr           (reset),
        .aclr           (reset),
        .data           ({32'hdeadbeef}),
        .clock          (clk),
        .rdreq          (accum_value_fifo_rdreq),
        .wrreq          (pkt_wr),
        .q              (accum_value_fifo_dataout),
        .empty          (accum_value_fifo_empty),
        .full           (accum_value_fifo_full),
        .usedw          ()
	);

	always@(posedge clk)
	begin
		if(reset) begin
			packet_sent <= 0;
		end
		else begin
			packet_sent <= (state==SEND_PUT_NETFPGA_HDR)?(packet_sent+1):(packet_sent);
		end
   end
	
   /* Modify the packet's hdrs and add the module hdr */
   always @(*) begin
      out_ctrl_next                 = out_ctrl;
      out_data_next                 = out_data;
      out_wr_next                   = 0;
      state_next                    = state;
      dram_fifo_read_next	    = 1'b0;
      accum_value_fifo_rdreq_next   = 1'b0;
      flushed_keys_next		    = flushed_keys;
      interpkt_gap_counter_next     = interpkt_gap_counter;
      words_per_packet_cnt_next	    = words_per_packet_cnt;
      word_sel_next		    = word_sel;
      tx_ext_update_rdreq_next = 1'b0;

   
      case(state)
        WAIT_DATA: begin
      		//Priority decoder
		if(!accum_value_fifo_empty) begin //send a packet with the currently accumulated value
			state_next = SEND_TCHECK_NETFPGA_HDR;
		end
		/*
		else if(!dram_fifo_empty) begin
			interpkt_gap_counter_next = interpkt_gap_cycles; //INTERPKT_CLK_CYCLES;
			state_next = FLUSH_DATA;
		end
		else if(tx_ext_update_almost_full)begin
			state_next = SEND_PUT_NETFPGA_HDR;
		end		
		*/
	end

	/****************************states to send put packets**************************/
	SEND_PUT_NETFPGA_HDR: begin
           if(out_rdy) begin
              out_wr_next   = 1;
              out_data_next = put_netfpga_header; //{16'h0001,16'h0009f,16'h0001,16'h004F8}; //{port_dst(16),word_len(16), port_src(16), byte_len(16)} //
	      out_ctrl_next = 8'hFF;
	      state_next    = SEND_PUT_HDR;
	      word_sel_next = 0;
	      
           end
	end

        SEND_PUT_HDR: begin
           if(out_rdy) begin
              out_wr_next   = 1'b1 ; //1'b1; //deepak - try to monitor packet_cnt //include not to synthesize away
	      out_data_next = put_header[word_sel]; //{next_hop_mac, src_mac_sel[47:32]};
              out_ctrl_next = 8'h00;
	      word_sel_next = word_sel+1;
	      if(word_sel==(MAX_WORDS_IN_PUT_HEADER-1)) begin
	      	   tx_ext_update_rdreq_next = 1'b1;
		   state_next = READ_PUT_WORD;
	      	   words_per_packet_cnt_next = words_per_packet_cnt+1;
	      end
	      else begin
	      	   tx_ext_update_rdreq_next = 1'b0;
		   state_next = SEND_PUT_HDR;
	      end

           end
        end // case: MOVE_MODULE_HDRS
	
	READ_PUT_WORD: begin
		state_next = SEND_PUT_PKT;
	end

	SEND_PUT_PKT: begin
           if(out_rdy) begin
              out_wr_next     		= 1;
              //out_data_next   		= tx_ext_update_q;
              //convert big endian to little endian before dispatch
              out_data_next   		= {key_little,val_little};
	      
	      if(words_per_packet_cnt==MAX_WORDS_PER_PACKET) begin //try 148!
              		out_ctrl_next   		= 8'h80;	//Transmit the last 64 bit word
			state_next 			= INTERPKT_GAP;//WAIT_DATA;
			words_per_packet_cnt_next 	= 0;
			interpkt_gap_counter_next 	= interpkt_gap_cycles; //INTERPKT_CLK_CYCLES;
	      end
	      else begin
			words_per_packet_cnt_next 	= words_per_packet_cnt+1;
			tx_ext_update_rdreq_next 	= 1'b1;
			state_next 			= READ_PUT_WORD;
			out_ctrl_next 			= 8'h00;	
	      end
           end
        end 

	INTERPKT_GAP:begin
		if(interpkt_gap_counter==0)
			state_next = WAIT_DATA;
		else
			interpkt_gap_counter_next = interpkt_gap_counter-1;
	end		

	/****************************states to send FLUSH packets**************************/
	//Each FLUSH data packet contains only 1 Key value pair from DRAM
	FLUSH_DATA:begin
                //Introduce an inter-packet gap (so that the slow software is not overwhelmed with packets in short time)
                if( (interpkt_gap_counter==0) && (!dram_fifo_empty) )
			state_next = SEND_FLUSH_NETFPGA_HDR;
                else
                        interpkt_gap_counter_next = interpkt_gap_counter-1;
	end

	SEND_FLUSH_NETFPGA_HDR: begin
           if(out_rdy) begin
              out_wr_next   = 1;
              out_data_next = flush_netfpga_header; //64'h0001000800010040; //{port_dst(16),word_len(16), port_src(16), byte_len(16)} //8 words = 64 bytes (0x40)
	      out_ctrl_next = 8'hFF;
	      state_next    = SEND_FLUSH_HDR;
	      word_sel_next = 0;
           end
	end

	SEND_FLUSH_HDR:begin
           if(out_rdy) begin
              out_wr_next   = 1;
	      out_data_next = flush_header[word_sel]; //{next_hop_mac, src_mac_sel[47:32]};
              out_ctrl_next = 8'h00;
	      if(word_sel==(MAX_WORDS_IN_HEADER-1)) begin
	      		state_next = READ_DRAM_WORD;
	      		dram_fifo_read_next = 1'b1;
	      end
	      else begin
			state_next = SEND_FLUSH_HDR;
	      end
	      word_sel_next = word_sel+1;
           end
	end

	READ_DRAM_WORD:begin
		state_next = SEND_FLUSH_PKT;
	end

	SEND_FLUSH_PKT: begin
	   if(out_rdy) begin
              	out_wr_next     = 1;
		out_data_next   = dram_fifo_readdata;
		out_ctrl_next   = 8'h80;

		if((flushed_keys==(num_keys-1))) begin //if we flushed all data return to idle state
			state_next = WAIT_DATA;
			flushed_keys_next = 0;
		end
		else begin
			state_next = FLUSH_DATA;
			flushed_keys_next = flushed_keys+1;
			interpkt_gap_counter_next = interpkt_gap_cycles; //INTERPKT_CLK_CYCLES;
		end 
	   end
	end

	/****************************states to send CHECK_TERMINATE packets**************************/
	//Each FLUSH data packet contains only 1 Key value pair from DRAM
	SEND_TCHECK_NETFPGA_HDR: begin
           if(out_rdy) begin
              out_wr_next   = 1;
              out_data_next = tcheck_netfpga_header; //64'h0001000800010040; //{port_dst(16),word_len(16), port_src(16), byte_len(16)} //8 bytes (0x40)
	      out_ctrl_next = 8'hFF;
	      state_next    = SEND_TCHECK_HDR;
	      word_sel_next = 0;
           end
	end

	SEND_TCHECK_HDR:begin
           if(out_rdy) begin
              out_wr_next   = 1;
	      out_data_next = tcheck_header[word_sel]; 
              out_ctrl_next = 8'h00;
	      if(word_sel==(MAX_WORDS_IN_HEADER-1)) begin
			state_next = READ_ACCUMULATE_WORD;
	      		accum_value_fifo_rdreq_next = 1'b1;
	      end
	      else begin
			state_next = SEND_TCHECK_HDR;
	      end
	      word_sel_next = word_sel+1;
           end
	end

	READ_ACCUMULATE_WORD:begin
		state_next = SEND_TCHECK_PKT;
	end

	SEND_TCHECK_PKT: begin
	   if(out_rdy) begin
              	out_wr_next     = 1;
		out_data_next   = {32'h0,accum_value_fifo_dataout};
		out_ctrl_next 	= 8'h80;
		state_next 	= WAIT_DATA;
	   end
	end
      endcase // case(state)
   end // always @ (*)

   always @(posedge clk) begin
      if(reset) begin
         state		  <=  WAIT_DATA;
	 out_data          <= 0;
         out_ctrl          <= 1;
         out_wr            <= 0;
 	 flushed_keys	   <= 0;
	 interpkt_gap_counter <= 0;
	 tx_ext_update_rdreq <= 0;
      	 words_per_packet_cnt <= 0;
	 word_sel	      <= 0;
	 dram_fifo_read	      <= 0;
	 accum_value_fifo_rdreq <= 0;
	 
      end
      else begin

	 //pipelined data and write signals 
	 //to sync the last data and wr_done signals
	 state             <= state_next;
         out_data          <= out_data_next;
         out_ctrl          <= out_ctrl_next;
         out_wr            <= out_wr_next;
	 flushed_keys 	   <= flushed_keys_next;
	 interpkt_gap_counter <= interpkt_gap_counter_next;
	 words_per_packet_cnt <= words_per_packet_cnt_next;
	 word_sel	   <= word_sel_next;
	 tx_ext_update_rdreq <= tx_ext_update_rdreq_next;
	 dram_fifo_read    <= dram_fifo_read_next;
	 accum_value_fifo_rdreq <= accum_value_fifo_rdreq_next;	
	 
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule // op_lut_process_sm

