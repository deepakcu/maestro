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
  module ip_arp
    #(parameter NUM_QUEUES = 8,
      parameter LUT_DEPTH = `ROUTER_OP_LUT_ARP_TABLE_DEPTH,
      parameter LUT_DEPTH_BITS = log2(LUT_DEPTH)
      )
   (// --- Interface to ip_arp
    input      [31:0]                  next_hop_ip,
    input      [NUM_QUEUES-1:0]        lpm_output_port,
    input                              lpm_vld,
    input                              lpm_hit,

    // --- interface to process block
    output     [47:0]                  next_hop_mac,
    output     [NUM_QUEUES-1:0]        output_port,
    output                             arp_mac_vld,
    output                             arp_lookup_hit,
    output                             lpm_lookup_hit,
    input                              rd_arp_result,

    // --- Interface to registers
    // --- Read port
    input [LUT_DEPTH_BITS-1:0]         arp_rd_addr,          // address in table to read
    input                              arp_rd_req,           // request a read
    output [47:0]                      arp_rd_mac,           // data read from the LUT at rd_addr
    output [31:0]                      arp_rd_ip,            // ip to match in the CAM
    output                             arp_rd_ack,           // pulses high

    // --- Write port
    input [LUT_DEPTH_BITS-1:0]         arp_wr_addr,
    input                              arp_wr_req,
    input [47:0]                       arp_wr_mac,
    input [31:0]                       arp_wr_ip,            // data to match in the CAM
    output                             arp_wr_ack,

    // --- Misc    
    input                              reset,
    input                              clk
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

   //--------------------- Internal Parameter-------------------------
   
   //---------------------- Wires and regs----------------------------
   wire                                  cam_busy;
   wire                                  cam_match;
   wire [LUT_DEPTH-1:0]                  cam_match_addr;
   wire [31:0]                           cam_cmp_din, cam_cmp_data_mask;
   wire [31:0]                           cam_din, cam_data_mask;
   wire                                  cam_we;
   wire [LUT_DEPTH_BITS-1:0]             cam_wr_addr;

   wire [47:0]                           next_hop_mac_result;

   wire                                  empty;
   
   reg [NUM_QUEUES-1:0]                  output_port_latched;
   reg                                   lpm_hit_latched;
   
        
   
   //------------------------- Modules-------------------------------

   // 1 cycle read latency, 2 cycles write latency
	/*
   bram_cam_unencoded_32x32 arp_cam
     (
      // Outputs
      .busy                             (cam_busy),
      .match                            (cam_match),
      .match_addr                       (cam_match_addr),
      // Inputs
      .clk                              (clk),
      .cmp_din                          (cam_cmp_din),
      .din                              (cam_din),
      .we                               (cam_we),
      .wr_addr                          (cam_wr_addr));
		*/
		
			//	wire cam_busy_signal_reg;
				 cam arp_cam
		 (
                .reset(reset),             
                .wr_clk(clk),             
                .wr_en(cam_we),             
                .wr_key(cam_din),             
                .wr_index(cam_wr_addr),           
                .wr_erase_n(1'b1),         
                .rd_clk(clk),             
                .rd_en(lpm_vld),              
                .rd_key(cam_cmp_din),             
                .one_hot_addr(cam_match_addr),       
                .match_addr(),         
                .match(cam_match),              
                .multi_match(),       
                .index_reg(),          
                .cam_full(),           
                .multi_index()         
                );
					 
			//assign 	cam_busy = 	cam_busy_signal_reg;
			//assign 	cam_busy = 	1'b0;
				   localparam
      IDLE_STATE_CAM = 2'b00,
      FIRST_STATE_CAM = 2'b01,
      SECOND_STATE_CAM = 2'b10;	

		reg [1:0] state_cam,state_cam_nxt;
      reg cam_busy_signal_reg,cam_busy_signal_reg_next;
		
	 always @(posedge clk) begin
      if (reset) begin
         state_cam <= IDLE_STATE_CAM;
			cam_busy_signal_reg <= 1'b0;
		end		
      else begin 
         state_cam <= state_cam_nxt;
         cam_busy_signal_reg <= cam_busy_signal_reg_next;
      end   // else
   end
	
	
	always @(*) begin      
      cam_busy_signal_reg_next = cam_busy_signal_reg;
      state_cam_nxt = state_cam;
      case (state_cam)
         IDLE_STATE_CAM: begin
            if (cam_we) begin
               cam_busy_signal_reg_next = 1'b1;
               state_cam_nxt = FIRST_STATE_CAM;
            end   
				else 
					cam_busy_signal_reg_next = 1'b0;
         end  
   
         FIRST_STATE_CAM: begin
               cam_busy_signal_reg_next = 1'b1;
               state_cam_nxt = SECOND_STATE_CAM;
         end   
        
         SECOND_STATE_CAM: begin
               cam_busy_signal_reg_next = 1'b0;
               state_cam_nxt = IDLE_STATE_CAM;
         end   

      endcase // case(state)

   end 
	assign 	cam_busy = 	cam_busy_signal_reg;
			
   unencoded_cam_lut_sm
     #(.CMP_WIDTH(32),                  // IPv4 addr width
       .DATA_WIDTH(48),
       .LUT_DEPTH(LUT_DEPTH)
       ) cam_lut_sm
       (// --- Interface for lookups
        .lookup_req         (lpm_vld),
        .lookup_cmp_data    (next_hop_ip),
        .lookup_cmp_dmask   (32'h0),
        .lookup_ack         (lookup_ack),
        .lookup_hit         (lookup_hit),
        .lookup_data        (next_hop_mac_result),
                                                                    
        // --- Interface to registers
        // --- Read port
        .rd_addr            (arp_rd_addr),    // address in table to read
        .rd_req             (arp_rd_req),     // request a read
        .rd_data            (arp_rd_mac),     // data found for the entry
        .rd_cmp_data        (arp_rd_ip),      // matching data for the entry
        .rd_cmp_dmask       (),               // don't cares entry
        .rd_ack             (arp_rd_ack),     // pulses high
                                                                    
        // --- Write port
        .wr_addr            (arp_wr_addr),
        .wr_req             (arp_wr_req),
        .wr_data            (arp_wr_mac),    // data found for the entry
        .wr_cmp_data        (arp_wr_ip),     // matching data for the entry
        .wr_cmp_dmask       (32'h0),         // don't cares for the entry
        .wr_ack             (arp_wr_ack),
                                                                    
        // --- CAM interface
        .cam_busy           (cam_busy),
        .cam_match          (cam_match),
        .cam_match_addr     (cam_match_addr),
        .cam_cmp_din        (cam_cmp_din),
        .cam_din            (cam_din),
        .cam_we             (cam_we),
        .cam_wr_addr        (cam_wr_addr),
        .cam_cmp_data_mask  (cam_cmp_data_mask),
        .cam_data_mask      (cam_data_mask),
                                                                    
        // --- Misc    
        .reset (reset),
        .clk   (clk));

   fallthrough_small_fifo #(.WIDTH(50+NUM_QUEUES), .MAX_DEPTH_BITS  (2))
      arp_fifo
        (.din           ({next_hop_mac_result, output_port_latched, lookup_hit, lpm_hit_latched}), // Data in
         .wr_en         (lookup_ack),             // Write enable
         .rd_en         (rd_arp_result),       // Read the next word 
         .dout          ({next_hop_mac, output_port, arp_lookup_hit, lpm_lookup_hit}),
         .full          (),
         .nearly_full   (),
         .prog_full     (),
         .empty         (empty),
         .reset         (reset),
         .clk           (clk)
         );

   //------------------------- Logic --------------------------------
   assign arp_mac_vld = !empty;
   always @(posedge clk) begin
      if(reset) begin
         output_port_latched <= 0;
         lpm_hit_latched <= 0;
      end
      else if(lpm_vld) begin
         output_port_latched <= lpm_output_port;
         lpm_hit_latched <= lpm_hit;
      end
   end

endmodule // ip_arp



