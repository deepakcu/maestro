// ============================================================================
// Copyright (c) 2010  
// ============================================================================
//
// Permission:
//
//   
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  
// ============================================================================
//           
//                     ReConfigurable Computing Group
//
//                     web: http://www.ecs.umass.edu/ece/tessier/rcg/
//                    
//
// ============================================================================
// Major Functions/Design Description:
//
//   
//
// ============================================================================
// Revision History:
// ============================================================================
//   Ver.: |Author:   |Mod. Date:    |Changes Made:
//   V1.0  |RCG       |05/10/2011    |
// ============================================================================
//include "NF_2.1_defines.v"
//include "registers.v"
//include "reg_defines_reference_router.v"

`include "../command_defines.v"

module op_lut_process_sm
  #(parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH = DATA_WIDTH/8,
    parameter NUM_QUEUES = 8,
    parameter NUM_QUEUES_WIDTH = log2(NUM_QUEUES),
    parameter STAGE_NUM  = 4,
    parameter IOQ_STAGE_NUM = 8'hff)
  (// --- interface to input fifo - fallthrough
   input                              in_fifo_vld,
   input [DATA_WIDTH-1:0]             in_fifo_data,
   input [CTRL_WIDTH-1:0]             in_fifo_ctrl,
   output reg                         in_fifo_rd_en,

   // --- interface to eth_parser
   input                              is_arp_pkt,
   input                              is_ip_pkt,
   input                              is_for_us,
   input                              is_broadcast,
   input                              eth_parser_info_vld,
   input      [NUM_QUEUES_WIDTH-1:0]  mac_dst_port_num,

   // --- interface to ip_arp
   input      [47:0]                  next_hop_mac,
   input      [NUM_QUEUES-1:0]        output_port,
   input                              arp_lookup_hit, // indicates if the next hop mac is correct
   input                              lpm_lookup_hit, // indicates if the route to the destination IP was found
   input                              arp_mac_vld,    // indicates the lookup is done

   // --- interface to op_lut_hdr_parser
   input                              is_from_cpu,
   input      [NUM_QUEUES-1:0]        to_cpu_output_port,   // where to send pkts this pkt if it has to go to the CPU
   input      [NUM_QUEUES-1:0]        from_cpu_output_port, // where to send this pkt if it is coming from the CPU
   input                              is_from_cpu_vld,
   input      [NUM_QUEUES_WIDTH-1:0]  input_port_num,

   // --- interface to IP_checksum
   input                              ip_checksum_vld,
   input                              ip_checksum_is_good,
   input                              ip_hdr_has_options,
   input      [15:0]                  ip_new_checksum,     // new checksum assuming decremented TTL
   input                              ip_ttl_is_good,
   input      [7:0]                   ip_new_ttl,

   // --- input to dest_ip_filter
   input                              dest_ip_hit,
   input                              dest_ip_filter_vld,

   // -- connected to all preprocess blocks
   output reg                         rd_preprocess_info,

   // --- interface to next module
   output reg                         out_wr,
   output reg [DATA_WIDTH-1:0]        out_data,
   output reg [CTRL_WIDTH-1:0]        out_ctrl,     // new checksum assuming decremented TTL
   input                              out_rdy,

   // --- interface to registers
   output reg                         pkt_sent_from_cpu,              // pulsed: we've sent a pkt from the CPU
   output reg                         pkt_sent_to_cpu_options_ver,    // pulsed: we've sent a pkt to the CPU coz it has options/bad version
   output reg                         pkt_sent_to_cpu_bad_ttl,        // pulsed: sent a pkt to the CPU coz the TTL is 1 or 0
   output reg                         pkt_sent_to_cpu_dest_ip_hit,    // pulsed: sent a pkt to the CPU coz it has hit in the destination ip filter list
   output reg                         pkt_forwarded     ,             // pulsed: forwarded pkt to the destination port
   output reg                         pkt_dropped_checksum,           // pulsed: dropped pkt coz bad checksum
   output reg                         pkt_sent_to_cpu_non_ip,         // pulsed: sent pkt to cpu coz it's not IP
   output reg                         pkt_sent_to_cpu_arp_miss,       // pulsed: sent pkt to cpu coz we didn't find arp entry for next hop ip
   output reg                         pkt_sent_to_cpu_lpm_miss,       // pulsed: sent pkt to cpu coz we didn't find lpm entry for destination ip
   output reg                         pkt_dropped_wrong_dst_mac,      // pulsed: dropped pkt not destined to us

   input  [47:0]                      mac_0,    // address of rx queue 0
   input  [47:0]                      mac_1,    // address of rx queue 1
   input  [47:0]                      mac_2,    // address of rx queue 2
   input  [47:0]                      mac_3,    // address of rx queue 3

   // -- avalon interface to access ethernet rx buffer (Deepak)
	input  [  9: 0] address,
   output [ 31: 0] readdata,
   input  [  3: 0]  byteenable,
   input            chipselect,
   input            write,
	input [ 31: 0] writedata,

    //i/f b/w op_lut_process_sm.v and RX EXT FIFO
    output  reg [63:0]   rx_ext_update_data,
    input                rx_ext_update_0_full,
    output               rx_ext_update_0_wrreq,
    input                rx_ext_update_1_full,
    output               rx_ext_update_1_wrreq,
    input                rx_ext_update_2_full,
    output               rx_ext_update_2_wrreq,
    input                rx_ext_update_3_full,
    output               rx_ext_update_3_wrreq,
    input             	 rx_ext_update_4_full,
    output               rx_ext_update_4_wrreq,
    input                rx_ext_update_5_full,
    output               rx_ext_update_5_wrreq,
    input                rx_ext_update_6_full,
    output               rx_ext_update_6_wrreq,
    input                rx_ext_update_7_full,
    output               rx_ext_update_7_wrreq,
   
output reg start_update,
   output reg flush_ddr,
   output reg check_terminate,
   output reg flush_data,
   output reg start_load,
   output reg compute_system_reset,


   //write interface to DDR (used by load data function)
   output reg [63:0] dram_fifo_writedata,
   output reg        dram_fifo_write,
   input             dram_fifo_full,

   input [7:0] proc_bit_mask,

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
   
   //------------------- Internal parameters -----------------------
   localparam NUM_STATES          = 10;
   localparam WAIT_PREPROCESS_RDY = 1;
   localparam MOVE_MODULE_HDRS    = 2;
   localparam SEND_SRC_MAC_LO     = 4;
   localparam SEND_IP_TTL         = 8;
   localparam SEND_IP_CHECKSUM    = 16;
   localparam MOVE_UDP            = 32;
   localparam INTERPRET_COMMAND   = 64;
   localparam LOAD_KEY_VALUE	  = 128;
   localparam ACCUM_KEY_VALUE     = 256;
   localparam DROP_PKT            = 512;

   //---------------------- Wires and regs -------------------------
   wire                 preprocess_vld;
   
   reg [NUM_STATES-1:0] state;
   reg [NUM_STATES-1:0] state_next;
   reg [DATA_WIDTH-1:0] out_data_next;
   reg [CTRL_WIDTH-1:0] out_ctrl_next;
   reg                  out_wr_next;
   reg                  ctrl_prev_is_0;
   wire                 eop;

   reg [47:0]           src_mac_sel;

   reg [NUM_QUEUES-1:0] dst_port;
   reg [NUM_QUEUES-1:0] dst_port_next;

   reg                  to_from_cpu;
   reg                  to_from_cpu_next;

   reg [63:0] rx_ext_update_data_next;
   reg [7:0]  rx_ext_update_wrreq, rx_ext_update_wrreq_next;
   wire [7:0] rx_ext_update_full;  
 
   reg [1:0] command, command_next;
   reg start_update_next;
   reg flush_ddr_next;
   reg start_load_next;
   reg check_terminate_next;
   reg flush_data_next;
   wire is_safe_to_write_packet;
   reg compute_system_reset_next;

   reg [63:0] dram_fifo_writedata_next;
   reg        dram_fifo_write_next;
   reg	[4:0] rx_ext_fifo_sel, rx_ext_fifo_sel_next;
   wire [4:0] next_external_fifo;

   reg [31:0] packet_rcv /*synthesis noprune*/;
   reg [31:0] packet_rcv_next /*synthesis noprune*/;

   assign rx_ext_update_0_wrreq = rx_ext_update_wrreq[0];
   assign rx_ext_update_1_wrreq = rx_ext_update_wrreq[1];
   assign rx_ext_update_2_wrreq = rx_ext_update_wrreq[2];
   assign rx_ext_update_3_wrreq = rx_ext_update_wrreq[3];
   assign rx_ext_update_4_wrreq = rx_ext_update_wrreq[4];
   assign rx_ext_update_5_wrreq = rx_ext_update_wrreq[5];
   assign rx_ext_update_6_wrreq = rx_ext_update_wrreq[6];
   assign rx_ext_update_7_wrreq = rx_ext_update_wrreq[7];

   assign  rx_ext_update_full[0] = rx_ext_update_0_full;
   assign  rx_ext_update_full[1] = rx_ext_update_1_full;
   assign  rx_ext_update_full[2] = rx_ext_update_2_full;
   assign  rx_ext_update_full[3] = rx_ext_update_3_full;
   assign  rx_ext_update_full[4] = rx_ext_update_4_full;
   assign  rx_ext_update_full[5] = rx_ext_update_5_full;
   assign  rx_ext_update_full[6] = rx_ext_update_6_full;
   assign  rx_ext_update_full[7] = rx_ext_update_7_full;

   reg [3:0] ext_start;

   always@(*) begin
	case(proc_bit_mask) //ext_start represents bit position in proc_mask
		8'h00: ext_start = 0;
		8'h01: ext_start = 1;
		8'h03: ext_start = 2;
		8'h07: ext_start = 3;
		8'h0f: ext_start = 4;
		8'h1f: ext_start = 5;
		8'h3f: ext_start = 6;
		8'h7f: ext_start = 7;
		8'hff: ext_start = 0; //Illegal - should never happen!
		default: ext_start = 0;	
	endcase
   end

   localparam INVALID=0;
   localparam LOAD=1;
   localparam ACCUMULATE=2;
	

   //-------------------------- Logic ------------------------------
   assign preprocess_vld = eth_parser_info_vld & ip_checksum_vld;

   assign eop = (ctrl_prev_is_0 && (in_fifo_ctrl!=0));

   /* select the src mac address to write in the forwarded pkt */
   always @(*) begin
      case(output_port)
        'h1: src_mac_sel       = mac_0;
        'h4: src_mac_sel       = mac_1;
        'h10: src_mac_sel      = mac_2;
        'h40: src_mac_sel      = mac_3;
        default: src_mac_sel   = mac_0;
      endcase // case(output_port)
   end
        
   /* Modify the packet's hdrs and add the module hdr */
   always @(*) begin
      rd_preprocess_info            = 0;
      state_next                    = state;
      in_fifo_rd_en                 = 0;
      pkt_dropped_wrong_dst_mac     = 0;
      
      rx_ext_update_data_next = rx_ext_update_data;
      rx_ext_update_wrreq_next = 1'b0;
   
      command_next = command; 
      //start_update_next = 1'b0;
      start_update_next = start_update;
      flush_ddr_next = 1'b0;
      start_load_next = start_load;       
      check_terminate_next = 1'b0;
      flush_data_next = 1'b0;
      dram_fifo_writedata_next = dram_fifo_writedata;
      dram_fifo_write_next = 1'b0;
      compute_system_reset_next = 1'b0;
      rx_ext_fifo_sel_next = rx_ext_fifo_sel;
      packet_rcv_next = packet_rcv;

      case(state)
        WAIT_PREPROCESS_RDY: begin
           if(preprocess_vld) begin
		//if(is_for_us && is_ip_pkt && ip_checksum_is_good) begin
		if(is_for_us && is_ip_pkt) begin //skip checksum for now
			state_next         = MOVE_MODULE_HDRS;
			packet_rcv_next = packet_rcv+1;
	         end // else: !if(ip_hdr_has_options | !ip_ttl_is_good)
	         else begin
	                pkt_dropped_wrong_dst_mac   = 1;
        	        rd_preprocess_info          = 1;
                	in_fifo_rd_en               = 1;
	                state_next                  = DROP_PKT;
        	end
	   end
        end // case: WAIT_PREPROCESS_RDY

        MOVE_MODULE_HDRS: begin
           if(in_fifo_vld) begin
              in_fifo_rd_en    = 1;
              if(in_fifo_ctrl==0) begin
                 state_next    = SEND_SRC_MAC_LO;
              end
           end
        end // case: MOVE_MODULE_HDRS

        SEND_SRC_MAC_LO: begin
           if(in_fifo_vld) begin
              in_fifo_rd_en   = 1;
              state_next      = SEND_IP_TTL;
           end
        end

        SEND_IP_TTL: begin
			  
           if(in_fifo_vld) begin
              in_fifo_rd_en   = 1;
              state_next      = SEND_IP_CHECKSUM;
           end
        end

        SEND_IP_CHECKSUM: begin
           if(in_fifo_vld) begin
              in_fifo_rd_en        = 1;
              rd_preprocess_info   = 1;
              state_next           = MOVE_UDP;
           end
        end
	
	MOVE_UDP: begin
	   if(in_fifo_vld) begin
              in_fifo_rd_en        = 1;
              state_next           = INTERPRET_COMMAND;
	   end
	end
     	
	INTERPRET_COMMAND: begin
	   if(in_fifo_vld) begin
              in_fifo_rd_en        = 1;
	      //interpret command here TODO
	      if(in_fifo_data[47:40]==`START_LOAD) begin
	 	 start_load_next = 1'b1;
		 state_next = DROP_PKT;		
	      end
	      else if(in_fifo_data[47:40]==`LOAD_DATA) begin
		 state_next = LOAD_KEY_VALUE;
	      end
	      else if(in_fifo_data[47:40]==`END_LOAD) begin
	         start_load_next = 1'b0;
		 compute_system_reset_next = 1'b1; //reset the compute system 
		 state_next = DROP_PKT;
	      end
	      else if(in_fifo_data[47:40]==`FPGA_TO_WORKER_PUT_REQUEST) begin //updates from FPGA workers to this FPGA
		  state_next = ACCUM_KEY_VALUE;
	      end
	      else if(in_fifo_data[47:40]==`WORKER_TO_FPGA_PUT_REQUEST) begin //updaets from CPU workers to this FPGA 
		  state_next = ACCUM_KEY_VALUE;
	      end
	      else if(in_fifo_data[47:40]==`START_UPDATE) begin
		  start_update_next = 1'b1;
		  state_next = DROP_PKT;
	      end
	      else if(in_fifo_data[47:40]==`END_UPDATE) begin
		  start_update_next = 1'b0;
		  state_next = DROP_PKT;
	      end
	      else if(in_fifo_data[47:40]==`START_CHECK_TERMINATE) begin
		  check_terminate_next = 1'b1;
		  state_next = DROP_PKT;	
	      end
	      else if(in_fifo_data[47:40]==`START_FLUSH_DATA) begin
		  flush_ddr_next = 1'b1;
		  state_next = DROP_PKT;	
	      end
	      else begin
              	  state_next   = DROP_PKT;
	      end
	   end //end if(in_fifo)
	end

	LOAD_KEY_VALUE: begin //FIX THIS 
           if(in_fifo_vld && (!dram_fifo_full)) begin
		dram_fifo_writedata_next = in_fifo_data[63:0];
		dram_fifo_write_next = 1'b1;
		state_next = (eop)?WAIT_PREPROCESS_RDY:LOAD_KEY_VALUE;
              	in_fifo_rd_en   = (eop)?0:1;
	    end
        end
	
	ACCUM_KEY_VALUE: begin
	   if(in_fifo_vld) begin
		//Make sure key!=0 AND val!=0
		//If rx fifo is full, simply DROP packets - dont head-of-line
		//block the packets
		if((|in_fifo_data)&&(!rx_ext_update_full[rx_ext_fifo_sel])) begin 
	      		rx_ext_update_data_next  = in_fifo_data[63:0];
			rx_ext_update_wrreq_next[rx_ext_fifo_sel] = 1'b1;
			rx_ext_fifo_sel_next = ((rx_ext_fifo_sel+1)==8)?ext_start:(rx_ext_fifo_sel+1);
		end

        	in_fifo_rd_en = 1'b1;
		if(eop) begin
			state_next = WAIT_PREPROCESS_RDY;
		end 
		else begin
			//state_next = DROP_PKT; 
			state_next = ACCUM_KEY_VALUE;
		end
	   end
	end

        DROP_PKT: begin
           if(in_fifo_vld) begin
              in_fifo_rd_en = 1;
              if(eop) begin
                 state_next = WAIT_PREPROCESS_RDY;
              end
           end
        end
      endcase // case(state)
   end // always @ (*)

   always @(posedge clk or posedge reset) begin
      if(reset) begin
         state             		<= WAIT_PREPROCESS_RDY;
         ctrl_prev_is_0    		<= 0;
         rx_ext_update_data 		<= 0;
         rx_ext_update_wrreq 		<= 0;
	 start_update 			<= 0;
	 start_load 			<= 0;
	 check_terminate 		<= 0;
	 flush_ddr 			<= 0;
         dram_fifo_writedata 		<= 0;
         dram_fifo_write 		<= 0;
	 compute_system_reset	 	<= 0;
         rx_ext_fifo_sel 		<= 0;
	 packet_rcv			<= 0;
      end
      else begin
         state             		<= state_next;
         ctrl_prev_is_0    		<= in_fifo_rd_en ? (in_fifo_ctrl==0) : ctrl_prev_is_0;
         rx_ext_update_data 		<= rx_ext_update_data_next;
         rx_ext_update_wrreq 		<= rx_ext_update_wrreq_next;
	 start_update 			<= start_update_next;
	 start_load 			<= start_load_next;
	 check_terminate 		<= check_terminate_next;
	 flush_ddr 			<= flush_ddr_next;
         dram_fifo_writedata 		<= dram_fifo_writedata_next;
         dram_fifo_write 		<= dram_fifo_write_next;
	 compute_system_reset	 	<= compute_system_reset_next;
         rx_ext_fifo_sel 		<= (rx_ext_fifo_sel_next<ext_start)?ext_start:rx_ext_fifo_sel_next;
	 packet_rcv			<= packet_rcv_next;
      end // else: !if(reset)
   end // always @ (posedge clk)

endmodule // op_lut_process_sm

