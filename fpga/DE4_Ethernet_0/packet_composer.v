
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
	parameter TOTAL_DATA=8,
	parameter MAX_NUM_WORKERS=4 //KARMA, DEEPAK-OPTIPLEX, RCG-STUDIO AND MAYA
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
   input [63:0]  		dram_fifo_readdata,
   output reg    		dram_fifo_read,
   input         		dram_fifo_empty,
   input [31:0]  		num_keys,
   input			start_update,

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_0_q,
output                 tx_ext_update_0_rdreq,
input                  tx_ext_update_0_empty,
input 		       tx_ext_update_0_almost_full,

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_1_q,
output                 tx_ext_update_1_rdreq,
input                  tx_ext_update_1_empty,
input 		       tx_ext_update_1_almost_full,

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_2_q,
output                 tx_ext_update_2_rdreq,
input                  tx_ext_update_2_empty,
input 		       tx_ext_update_2_almost_full,

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_3_q,
output                 tx_ext_update_3_rdreq,
input                  tx_ext_update_3_empty,
input 		       tx_ext_update_3_almost_full,

   input [31:0]		  interpkt_gap_cycles,
   input [31:0]		  shard_id,
   input [31:0]		  log_2_num_workers_in,

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

   reg dram_fifo_read_next;
	
   //------------------- Internal parameters -----------------------
   //Hardcode IP headers (simplfies our hardware logic)
     
   localparam NUM_STATES        = 14;
   localparam WAIT_DATA	   	= 0;
   localparam WAIT_READ		= 1;
   localparam PARSE_KEY		= 2;
   localparam WAIT_CYCLE	= 3;
   localparam NETFPGA_HDR 	= 4;
   localparam WORD_0	   	= 5;
   localparam WORD_1		= 6;
   localparam WORD_2         	= 7;
   localparam WORD_3		= 8;
   localparam WORD_4 	    	= 9;
   localparam WORD_5		= 10;
   localparam WORD_6	    	= 11;
   localparam WORD_7		= 12;
   localparam INTERPKT_GAP      = 13;
   
   localparam PUT	=1;
   localparam FLUSH	=2;
   localparam TCHECK	=3;
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
   reg [31:0] packet_sent_next /*synthesis noprune*/;
   reg [31:0] key, key_next, val, val_next;
   //wire [31:0] key_little; //key in little endian format;
   //wire [31:0] val_little; //val in little endian format;

   //assign key = tx_ext_update_q[63:32];
   //assign val = tx_ext_update_q[31:0];
   //assign key_little = {key[7:0],key[15:8],key[23:16],key[31:24]};
   //assign val_little = {val[7:0],val[15:8],val[23:16],val[31:24]};


   wire [31:0] mask;
   assign mask = ~({32{1'b1}}<<log_2_num_workers_in);
   wire [31:0] target_shard_id;
   assign target_shard_id = key&mask;

   //-------------------------- Logic ------------------------------

   localparam INTERPKT_CLK_CYCLES  = 8000; //try doubling the cycles from 4000 to 8000- as software is still overwhelmed with packet floods


   reg [MAX_NUM_WORKERS-1:0] tx_ext_update_rdreq, tx_ext_update_rdreq_next;// tx_ext_update_rdreq_next;
   wire [MAX_NUM_WORKERS-1:0] tx_ext_update_full;// tx_ext_update_rdreq_next;
   wire [MAX_NUM_WORKERS-1:0] tx_ext_update_empty;// tx_ext_update_rdreq_next;
   wire [MAX_NUM_WORKERS-1:0] tx_ext_update_almost_empty;// tx_ext_update_rdreq_next;
   wire [MAX_NUM_WORKERS-1:0]	tx_ext_update_almost_full;
	wire  [63:0]         tx_ext_update_q[MAX_NUM_WORKERS-1:0];


   //`include "headers.v"
   //A small fifo to store the iteration accumulate value
   txfifo #(
        .DATA_WIDTH(32),
        .LOCAL_FIFO_DEPTH(4)

   ) accum_value_fifo (
        //.aclr           (reset),
        .aclr           (reset),
        .data           (iteration_accum_value),
        .clock          (clk),
        .rdreq          (accum_value_fifo_rdreq),
        .wrreq          (iteration_terminate_check),
        .q              (accum_value_fifo_dataout),
        .empty          (accum_value_fifo_empty),
        .full           (accum_value_fifo_full),
        .usedw          ()
  );

   reg [1:0] select, select_next;
   wire [DATA_WIDTH-1:0] netfpga_header;

   wire [IP_ADDR_WIDTH-1:0] 		fpga_ip[MAX_NUM_WORKERS-1:0];
   wire [IP_ADDR_WIDTH-1:0] 		asst_ip[MAX_NUM_WORKERS-1:0];
   wire [MAC_ADDR_WIDTH-1:0] 		asst_mac[MAX_NUM_WORKERS-1:0];
   wire [MAC_ADDR_WIDTH-1:0]		nf2_mac[3:0]; //MACS OF NetFPGA ports
   wire [MAC_ADDR_WIDTH-1:0]		router_mac[3:0]; //MACS OF Router ports

   assign fpga_ip[0]=32'h0a010101; //10.1.1.1
   assign fpga_ip[1]=32'h14010101; //20.1.1.1
   assign fpga_ip[2]=32'h1E010101; //30.1.1.1
   assign fpga_ip[3]=32'h28010101; //40.1.1.1

   assign asst_ip[0]=32'h0a010102; //10.1.1.2
   assign asst_ip[1]=32'h14010102; //20.1.1.2
   assign asst_ip[2]=32'h1E010102; //30.1.1.2
   assign asst_ip[3]=32'h28010102; //40.1.1.2

   assign asst_mac[0]=48'h0014d1176bee; //karma eth1 mac
   assign asst_mac[1]=48'h0014d1176be2; //deepak-OptiPlex-780 eth1 mac
   assign asst_mac[2]=48'h0014d1265344; //rcg-studio eth1 mac
   assign asst_mac[3]=48'h0014d125d09f; //maya eth1 mac

   assign nf2_mac[0]=48'h004e46324300;
   assign nf2_mac[1]=48'h004e46324301;
   assign nf2_mac[2]=48'h004e46324302;
   assign nf2_mac[3]=48'h004e46324303;

   assign router_mac[0]=48'h004e46324300; //karma ->nf2c0 of NetFPGA
   assign router_mac[1]=48'h004e46324301; //optiPlex -> nf2c1 of NetFPGA
   assign router_mac[2]=48'h004e46324302; //rcg-studio -> nf2c2 of NetFPGA
   assign router_mac[3]=48'h004e46324303; //maya -> nf2c3 of NetFPGA
  


   wire [IP_ADDR_WIDTH-1:0] 		src_ip;
   wire [IP_ADDR_WIDTH-1:0] 		dst_ip;
   wire [MAC_ADDR_WIDTH-1:0] 		src_mac;
   wire [MAC_ADDR_WIDTH-1:0] 		dst_mac;
   wire [15:0]				checksum;

   reg [31:0]				pkt_count, pkt_count_next;

   //   assign netfpga_header = 64'h0001000800010040;
   //   all PUT requests exit through port nf2c1 (port code msb 16 bits of header = 00004)
   //   PUT packet will carry 150 KV pairs = 7 header words + 150 KV words
   //   total 157 (0x9d) words or 157*8 bytes=1256 (0x4e8) bytes
   //assign netfpga_header 	= (select==PUT)?64'h0004000800010040:64'h0001000800010040;
   assign netfpga_header 	= (select==PUT)?64'h0004009d000104e8:64'h0001000800010040;
   assign src_ip  		= fpga_ip[shard_id];
   assign dst_ip  		= (select==PUT)?fpga_ip[target_shard_id]:asst_ip[shard_id]; 
   assign src_mac 		= (select==PUT)?nf2_mac[1]:48'h004e46324300; //Use eth0 port of netfpga always
   //assign dst_mac 		= (select==PUT)?nf2_mac[2]:asst_mac[shard_id];
   assign dst_mac 		= (select==PUT)?router_mac[shard_id]:asst_mac[shard_id];

	wire [15:0] 	ether_type_16;
	wire [3:0]	ip_version_4;
	wire [3:0]	ip_hdr_length_4;
	wire [7:0]	ip_tos_8;

	wire [15:0] 	ip_total_length_16;
	wire [15:0]	ip_id_16;
	wire [2:0]	ip_flags_3;
	wire [12:0]	ip_flag_offset_13;
	wire [7:0]	ip_ttl_8;
	wire [7:0]	ip_prot_8;

	wire [15:0] 	udp_src_16;
	wire [15:0] 	udp_dst_16;
	wire [15:0] 	udp_length_16;

	//08004510
	assign 	ether_type_16=16'h0800 ;
	assign	ip_version_4=4'h4;
	assign	ip_hdr_length_4=4'h5;
	assign	ip_tos_8=8'h10;

	assign 	ip_total_length_16=(select==PUT)?16'h04da:16'h0032;
	assign	ip_id_16=16'hd431;
	assign	ip_flags_3=3'h0;
	assign	ip_flag_offset_13=13'h0;
	assign	ip_ttl_8=8'h14;
	assign	ip_prot_8=8'h11;

	assign 	udp_src_16=16'h001e;	//use UDP port 30
	assign 	udp_dst_16=16'h001e;	//use UDP port 30
	assign 	udp_length_16=16'h001e; //ignore UDP length



assign tx_ext_update_q[0] 		= tx_ext_update_0_q;
assign tx_ext_update_0_rdreq 		= tx_ext_update_rdreq[0];
assign tx_ext_update_empty[0]		= tx_ext_update_0_empty;
assign tx_ext_update_almost_full[0]	= tx_ext_update_0_almost_full;

assign tx_ext_update_q[1] 		= tx_ext_update_1_q;
assign tx_ext_update_1_rdreq 		= tx_ext_update_rdreq[1];
assign tx_ext_update_empty[1]		= tx_ext_update_1_empty;
assign tx_ext_update_almost_full[1]	= tx_ext_update_1_almost_full;

assign tx_ext_update_q[2] 		= tx_ext_update_2_q;
assign tx_ext_update_2_rdreq 		= tx_ext_update_rdreq[2];
assign tx_ext_update_empty[2]		= tx_ext_update_2_empty;
assign tx_ext_update_almost_full[2]	= tx_ext_update_2_almost_full;

assign tx_ext_update_q[3] 		= tx_ext_update_3_q;
assign tx_ext_update_3_rdreq 		= tx_ext_update_rdreq[3];
assign tx_ext_update_empty[3]		= tx_ext_update_3_empty;
assign tx_ext_update_almost_full[3]	= tx_ext_update_3_almost_full;

reg [log2(MAX_NUM_WORKERS)-1:0] sel_tx_fifo, sel_tx_fifo_next;

	binary_adder_tree binary_adder_tree (	.A({ip_version_4,ip_hdr_length_4,ip_tos_8}),
				.B({ip_total_length_16}),
				.C({ip_id_16}),
				.D({ip_flags_3,ip_flag_offset_13}),
				.E({ip_ttl_8,ip_prot_8}),
				.F({src_ip[31:16]}),
				.G({src_ip[15:0]}),
				.H({dst_ip[31:16]}),
				.I({dst_ip[15:0]}),
				.checksum_reg(checksum),
				.clk(clk)
		);
	
	reg [63:0] command_word;
	
	always@(*) begin
		case(select)
			PUT: 		command_word = 64'h0000090000000000;
			FLUSH: 		command_word = 64'h00000a0000000000;
			TCHECK:		command_word = 64'h00000b0000000000;
			default:	command_word = 64'h0000000000000000;
		endcase
	end

reg [31:0] 	timeout;
reg start_timeout, start_timeout_next;
wire timeout_expired;
assign timeout_expired = (timeout==0)&(start_timeout==0);

always@(posedge clk) 
begin
	if(reset) begin
		timeout <= 0;	
	end 
	else begin
		if(start_timeout) begin
			timeout <= interpkt_gap_cycles;
		end
		else if(timeout_expired) begin
			timeout <= 0;
		end
		else begin
			timeout <= timeout-1;
		end
	end
end

   /* Modify the packet's hdrs and add the module hdr */
   always @(*) begin
      state_next                    = state;
      dram_fifo_read_next	    = 1'b0;
      accum_value_fifo_rdreq_next   = 1'b0;
//      interpkt_gap_counter_next     = interpkt_gap_counter;
	start_timeout_next		= 0;
      tx_ext_update_rdreq_next 	    = 1'b0;
      select_next		    = select;
      out_data_next          	    = out_data;
      out_ctrl_next          	    = out_ctrl;
      out_wr_next            	    = 0;
      key_next			    = key;
      val_next			    = val;
      pkt_count_next		    = pkt_count;
      sel_tx_fifo_next		    = sel_tx_fifo;
      packet_sent_next		    = packet_sent;

      case(state)
        WAIT_DATA: begin
		pkt_count_next = 0;
      		//Priority decoder
		if(!accum_value_fifo_empty) begin //send a packet with the currently accumulated value
			accum_value_fifo_rdreq_next = 1;
			state_next = WAIT_READ;
			select_next = TCHECK;
		end
		else if(!dram_fifo_empty) begin
			dram_fifo_read_next = 1;
			state_next = WAIT_READ;
			select_next = FLUSH;
		end
		else if(tx_ext_update_almost_full[sel_tx_fifo]&start_update)begin 
			tx_ext_update_rdreq_next[sel_tx_fifo] = 1;
			state_next = WAIT_READ;
			select_next = PUT;
			packet_sent_next = packet_sent+1;
		end
		else begin
			sel_tx_fifo_next = sel_tx_fifo+1;
		end		
	end

	WAIT_READ:begin
		if(out_rdy) begin
			state_next = PARSE_KEY;
		end
	end

	PARSE_KEY:begin
		case(select) 
			PUT:		key_next = tx_ext_update_q[sel_tx_fifo][63:32];
			FLUSH:		key_next = dram_fifo_readdata[63:32];
			TCHECK:		key_next = 0;
			default:	key_next = 0;
		endcase
		case(select)
			PUT:		val_next = tx_ext_update_q[sel_tx_fifo][31:0];
			FLUSH:		val_next = dram_fifo_readdata[31:0];
			TCHECK:		val_next = accum_value_fifo_dataout[31:0];
			default:	val_next = 0;
		endcase

		if(select==PUT) begin
			if(pkt_count==150) begin
				state_next = INTERPKT_GAP; //last kv pair
				start_timeout_next = 1;
				//interpkt_gap_counter_next = interpkt_gap_cycles;
			end
			else if(pkt_count==0) begin //first kv pair
				state_next = WAIT_CYCLE;
			end
			else begin //any other kv pair
				state_next = WORD_7;
			end
		end
		else begin
			state_next = WAIT_CYCLE;
		end
	end

	WAIT_CYCLE:begin
		state_next = NETFPGA_HDR;
	end

	//see http://www.stanford.edu/~hyzeng/paper/airfpga.pdf to understand
	//NetFPGA packet headers
	NETFPGA_HDR:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= netfpga_header; //{16'h0001,16'h0009f,16'h0001,16'h004F8}; //{port_dst(16),word_len(16), port_src(16), byte_len(16)} //
			out_ctrl_next 	= 8'hFF;
	      		state_next  	= WORD_0;
		end
	end

	WORD_0:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {dst_mac,src_mac[47:32]};
			out_ctrl_next 	= 8'h00;
	      		state_next  	= WORD_1;
		end
	end



	WORD_1:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {src_mac[31:0],ether_type_16,ip_version_4,ip_hdr_length_4,ip_tos_8};
			out_ctrl_next	= 8'h00;
	      		state_next  	= WORD_2;
		end
	end


	WORD_2:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {ip_total_length_16,ip_id_16,ip_flags_3,ip_flag_offset_13,ip_ttl_8,ip_prot_8};
			out_ctrl_next	= 8'h00;
	      		state_next  	= WORD_3;
		end
	end


	WORD_3:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {checksum,src_ip,dst_ip[31:16]};
			out_ctrl_next	= 8'h00;
	      		state_next  	= WORD_4;
		end
	end


	WORD_4:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {dst_ip[15:0],udp_src_16,udp_dst_16,udp_length_16};
			out_ctrl_next	= 8'h00;
	      		state_next  	= WORD_5;
		end
	end

	WORD_5:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {command_word};
			out_ctrl_next	= 8'h00;
			state_next    	= WORD_6;
		end
	end

	WORD_6:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
			out_data_next 	= {64'h0};
			out_ctrl_next	= 8'h00;
			state_next    	= WORD_7;
		end
	end

	WORD_7:begin
		if(out_rdy) begin
              		out_wr_next 	= 1;
		        out_data_next 	= {key,val};	
			if(select==PUT) begin
				tx_ext_update_rdreq_next[sel_tx_fifo] 	 = (pkt_count==149)?0:1;
				out_ctrl_next				 = (pkt_count==149)?8'h80:8'h00;
	      			state_next  		  		 = WAIT_READ;
				pkt_count_next  			 = pkt_count+1;
			end
			else begin
				out_ctrl_next	= 8'h80;
	      			state_next    	= WAIT_DATA;
			end
		end
	end

	INTERPKT_GAP:begin
		if(timeout_expired) begin
			state_next = WAIT_DATA;
		end
	end	
 endcase	
end




   always @(posedge clk) begin
      if(reset) begin
	 state		   	<= WAIT_DATA;
	 out_data          	<= 0;
         out_ctrl          	<= 1;
         out_wr            	<= 0;
	// interpkt_gap_counter 	<= 0;
	 start_timeout		<= 0;
	 tx_ext_update_rdreq 	<= 0;
	 dram_fifo_read	      	<= 0;
	 accum_value_fifo_rdreq <= 0;
	 select 		<= 0;
      	 out_data	    	<= 0;
      	 out_ctrl	    	<= 0;  
      	 key			<= 0;
      	 val			<= 0;
	 pkt_count		<= 0;
	 sel_tx_fifo		<= 0;
	 packet_sent		<= 0;
      end
      else begin

	 //pipelined data and write signals 
	 //to sync the last data and wr_done signals
	 state             	<= state_next;
         out_data          	<= out_data_next;
         out_ctrl          	<= out_ctrl_next;
         out_wr            	<= out_wr_next;
	 //interpkt_gap_counter 	<= interpkt_gap_counter_next;
	 start_timeout		<= start_timeout_next;
	 tx_ext_update_rdreq 	<= tx_ext_update_rdreq_next;
	 dram_fifo_read    	<= dram_fifo_read_next;
	 accum_value_fifo_rdreq <= accum_value_fifo_rdreq_next;	
	 select 		<= select_next;
      	 out_data	    	<= out_data_next;
      	 out_ctrl	    	<= out_ctrl_next;  
      	 key			<= key_next;
      	 val			<= val_next;
	 pkt_count		<= pkt_count_next;
	 sel_tx_fifo		<= sel_tx_fifo_next;
	 packet_sent		<= packet_sent_next;
      end // else: !if(reset)
   end // always @ (posedge clk)



endmodule // op_lut_process_sm

