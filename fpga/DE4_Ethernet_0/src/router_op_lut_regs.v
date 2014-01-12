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
module router_op_lut_regs
   #( parameter NUM_QUEUES = 5,
       parameter ARP_LUT_DEPTH_BITS = 4,
       parameter LPM_LUT_DEPTH_BITS = 4,
       parameter FILTER_DEPTH_BITS = 4,
       parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_out,
      output [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_out,
      output [UDP_REG_SRC_WIDTH-1:0]      reg_src_out,

      // --- interface to op_lut_process_sm
      input                               pkt_sent_from_cpu,              // pulsed: we've sent a pkt from the CPU
      input                               pkt_sent_to_cpu_options_ver,    // pulsed: we've sent a pkt to the CPU coz it has options/bad version
      input                               pkt_sent_to_cpu_bad_ttl,        // pulsed: sent a pkt to the CPU coz the TTL is 1 or 0
      input                               pkt_sent_to_cpu_dest_ip_hit,    // pulsed: sent a pkt to the CPU coz it has hit in the destination ip filter list
      input                               pkt_forwarded     ,             // pulsed: forwarded pkt to the destination port
      input                               pkt_dropped_checksum,           // pulsed: dropped pkt coz bad checksum
      input                               pkt_sent_to_cpu_non_ip,         // pulsed: sent pkt to cpu coz it's not IP
      input                               pkt_sent_to_cpu_arp_miss,       // pulsed: sent pkt to cpu coz we didn't find arp entry for next hop ip
      input                               pkt_sent_to_cpu_lpm_miss,       // pulsed: sent pkt to cpu coz we didn't find lpm entry for destination ip
      input                               pkt_dropped_wrong_dst_mac,      // pulsed: dropped pkt not destined to us

      // --- interface to ip_lpm
      output [LPM_LUT_DEPTH_BITS-1:0 ]    lpm_rd_addr,          // address in table to read
      output                              lpm_rd_req,           // request a read
      input [31:0]                        lpm_rd_ip,            // ip to match in the CAM
      input [31:0]                        lpm_rd_mask,          // subnet mask
      input [NUM_QUEUES-1:0]              lpm_rd_oq,            // input queue
      input [31:0]                        lpm_rd_next_hop_ip,   // ip addr of next hop
      input                               lpm_rd_ack,           // pulses high
      output [LPM_LUT_DEPTH_BITS-1:0]     lpm_wr_addr,
      output                              lpm_wr_req,
      output [NUM_QUEUES-1:0]             lpm_wr_oq,
      output [31:0]                       lpm_wr_next_hop_ip,   // ip addr of next hop
      output [31:0]                       lpm_wr_ip,            // data to match in the CAM
      output [31:0]                       lpm_wr_mask,
      input                               lpm_wr_ack,

      // --- ip_arp
      output [ARP_LUT_DEPTH_BITS-1:0]     arp_rd_addr,          // address in table to read
      output                              arp_rd_req,           // request a read
      input  [47:0]                       arp_rd_mac,           // data read from the LUT at rd_addr
      input  [31:0]                       arp_rd_ip,            // ip to match in the CAM
      input                               arp_rd_ack,           // pulses high
      output [ARP_LUT_DEPTH_BITS-1:0]     arp_wr_addr,
      output                              arp_wr_req,
      output [47:0]                       arp_wr_mac,
      output [31:0]                       arp_wr_ip,            // data to match in the CAM
      input                               arp_wr_ack,

      // --- interface to dest_ip_filter
      output [FILTER_DEPTH_BITS-1:0]      dest_ip_filter_rd_addr,          // address in table to read
      output                              dest_ip_filter_rd_req,           // request a read
      input [31:0]                        dest_ip_filter_rd_ip,            // ip to match in the CAM
      input                               dest_ip_filter_rd_ack,           // pulses high
      output [FILTER_DEPTH_BITS-1:0]      dest_ip_filter_wr_addr,
      output                              dest_ip_filter_wr_req,
      output [31:0]                       dest_ip_filter_wr_ip,            // data to match in the CAM
      input                               dest_ip_filter_wr_ack,

      // --- eth_parser
      output [47:0]                       mac_0,    // address of rx queue 0
      output [47:0]                       mac_1,    // address of rx queue 1
      output [47:0]                       mac_2,    // address of rx queue 2
      output [47:0]                       mac_3,    // address of rx queue 3

      output [31:0]			  num_keys,
      output [31:0]                       log_2_num_workers, //returns the log2(number of workers) - useful for mask calculation in key hashing
      output [31:0]			  shard_id,
      output [31:0]			  max_n_values,
      output [31:0]                       filter_threshold,
      output [31:0]			   interpkt_gap_cycles, //gap (in cycles) b/w two PUT packets
     output [3:0]  max_fpga_procs,
     output [7:0]			   proc_bit_mask,
     output	  algo_selection,

      input                               clk,
      input                               reset
    );

   // ------------- Wires/reg ------------------

   wire                            reg_req_internal;
   wire                            reg_ack_internal;
   wire                            reg_rd_wr_L_internal;
   wire [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_internal;
   wire [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_internal;
   wire [UDP_REG_SRC_WIDTH-1:0]    reg_src_internal;
      

   // ------------- Modules ------------------

   router_op_lut_regs_non_cntr #( 
      .NUM_QUEUES (NUM_QUEUES),
      .ARP_LUT_DEPTH_BITS (ARP_LUT_DEPTH_BITS),
      .LPM_LUT_DEPTH_BITS (LPM_LUT_DEPTH_BITS),
      .FILTER_DEPTH_BITS (FILTER_DEPTH_BITS),
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) router_op_lut_regs_non_cntr (
      .reg_req_in                (reg_req_in),
      .reg_ack_in                (reg_ack_in),
      .reg_rd_wr_L_in            (reg_rd_wr_L_in),
      .reg_addr_in               (reg_addr_in),
      .reg_data_in               (reg_data_in),
      .reg_src_in                (reg_src_in),

      .reg_req_out               (reg_req_internal),
      .reg_ack_out               (reg_ack_internal),
      .reg_rd_wr_L_out           (reg_rd_wr_L_internal),
      .reg_addr_out              (reg_addr_internal),
      .reg_data_out              (reg_data_internal),
      .reg_src_out               (reg_src_internal),

      // --- interface to ip_lpm
      .lpm_rd_addr               (lpm_rd_addr),          // address in table to read
      .lpm_rd_req                (lpm_rd_req),           // request a read
      .lpm_rd_ip                 (lpm_rd_ip),            // ip to match in the CAM
      .lpm_rd_mask               (lpm_rd_mask),          // subnet mask
      .lpm_rd_oq                 (lpm_rd_oq),            // input queue
      .lpm_rd_next_hop_ip        (lpm_rd_next_hop_ip),   // ip addr of next hop
      .lpm_rd_ack                (lpm_rd_ack),           // pulses high
      .lpm_wr_addr               (lpm_wr_addr),
      .lpm_wr_req                (lpm_wr_req),
      .lpm_wr_oq                 (lpm_wr_oq),
      .lpm_wr_next_hop_ip        (lpm_wr_next_hop_ip),   // ip addr of next hop
      .lpm_wr_ip                 (lpm_wr_ip),            // data to match in the CAM
      .lpm_wr_mask               (lpm_wr_mask),
      .lpm_wr_ack                (lpm_wr_ack),

      // --- ip_arp
      .arp_rd_addr               (arp_rd_addr),          // address in table to read
      .arp_rd_req                (arp_rd_req),           // request a read
      .arp_rd_mac                (arp_rd_mac),           // data read from the LUT at rd_addr
      .arp_rd_ip                 (arp_rd_ip),            // ip to match in the CAM
      .arp_rd_ack                (arp_rd_ack),           // pulses high
      .arp_wr_addr               (arp_wr_addr),
      .arp_wr_req                (arp_wr_req),
      .arp_wr_mac                (arp_wr_mac),
      .arp_wr_ip                 (arp_wr_ip),            // data to match in the CAM
      .arp_wr_ack                (arp_wr_ack),

      // --- interface to dest_ip_filter
      .dest_ip_filter_rd_addr    (dest_ip_filter_rd_addr),          // address in table to read
      .dest_ip_filter_rd_req     (dest_ip_filter_rd_req),           // request a read
      .dest_ip_filter_rd_ip      (dest_ip_filter_rd_ip),            // ip to match in the CAM
      .dest_ip_filter_rd_ack     (dest_ip_filter_rd_ack),           // pulses high
      .dest_ip_filter_wr_addr    (dest_ip_filter_wr_addr),
      .dest_ip_filter_wr_req     (dest_ip_filter_wr_req),
      .dest_ip_filter_wr_ip      (dest_ip_filter_wr_ip),            // data to match in the CAM
      .dest_ip_filter_wr_ack     (dest_ip_filter_wr_ack),

      // --- eth_parser
      .mac_0                     (mac_0),    // address of rx queue 0
      .mac_1                     (mac_1),    // address of rx queue 1
      .mac_2                     (mac_2),    // address of rx queue 2
      .mac_3                     (mac_3),    // address of rx queue 3

      .shard_id			 (shard_id),
      .max_n_values		 (max_n_values),
      .filter_threshold	         (filter_threshold),
      .num_keys			 (num_keys),
      .log_2_num_workers 	 (log_2_num_workers),
      .interpkt_gap_cycles	 (interpkt_gap_cycles),
      .max_fpga_procs		 (max_fpga_procs),
.proc_bit_mask(proc_bit_mask),
      .algo_selection		 (algo_selection),


      .clk                       (clk),
      .reset                     (reset)
    );

   router_op_lut_regs_cntr #( 
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) router_op_lut_regs_cntr (
      .reg_req_in                            (reg_req_internal),
      .reg_ack_in                            (reg_ack_internal),
      .reg_rd_wr_L_in                        (reg_rd_wr_L_internal),
      .reg_addr_in                           (reg_addr_internal),
      .reg_data_in                           (reg_data_internal),
      .reg_src_in                            (reg_src_internal),

      .reg_req_out                           (reg_req_out),
      .reg_ack_out                           (reg_ack_out),
      .reg_rd_wr_L_out                       (reg_rd_wr_L_out),
      .reg_addr_out                          (reg_addr_out),
      .reg_data_out                          (reg_data_out),
      .reg_src_out                           (reg_src_out),

      // --- interface to op_lut_process_sm
      .pkt_sent_from_cpu                     (pkt_sent_from_cpu),
      .pkt_sent_to_cpu_options_ver           (pkt_sent_to_cpu_options_ver),
      .pkt_sent_to_cpu_bad_ttl               (pkt_sent_to_cpu_bad_ttl),
      .pkt_sent_to_cpu_dest_ip_hit           (pkt_sent_to_cpu_dest_ip_hit),
      .pkt_forwarded                         (pkt_forwarded),
      .pkt_dropped_checksum                  (pkt_dropped_checksum),
      .pkt_sent_to_cpu_non_ip                (pkt_sent_to_cpu_non_ip),
      .pkt_sent_to_cpu_arp_miss              (pkt_sent_to_cpu_arp_miss),
      .pkt_sent_to_cpu_lpm_miss              (pkt_sent_to_cpu_lpm_miss),
      .pkt_dropped_wrong_dst_mac             (pkt_dropped_wrong_dst_mac),

      .clk                                   (clk),
      .reset                                 (reset)
    );

endmodule
