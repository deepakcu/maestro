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
//include "reg_defines_reference_router.v"
module oq_regs_eval_empty
  #( 
      parameter SRAM_ADDR_WIDTH     = 13,
      parameter CTRL_WIDTH          = 8,
      parameter UDP_REG_SRC_WIDTH   = 2,
      parameter NUM_OUTPUT_QUEUES   = 8,
      parameter NUM_OQ_WIDTH        = log2(NUM_OUTPUT_QUEUES),
      parameter PKT_LEN_WIDTH       = 11,
      parameter PKT_WORDS_WIDTH     = PKT_LEN_WIDTH-log2(CTRL_WIDTH),
      parameter MAX_PKT             = 2048/CTRL_WIDTH,   // allow for 2K bytes,
      parameter MIN_PKT             = 60/CTRL_WIDTH + 1,
      parameter PKTS_IN_RAM_WIDTH   = log2((2**SRAM_ADDR_WIDTH)/MIN_PKT)
   )
   
   ( 
      // --- Inputs from dst update ---
      input                               dst_update,
      input [NUM_OQ_WIDTH-1:0]            dst_oq,
      input [PKTS_IN_RAM_WIDTH-1:0]       dst_num_pkts_in_q,
      input                               dst_num_pkts_in_q_done,

      // --- Inputs from src update ---
      input                               src_update,
      input [NUM_OQ_WIDTH-1:0]            src_oq,
      input [PKTS_IN_RAM_WIDTH-1:0]       src_num_pkts_in_q,
      input                               src_num_pkts_in_q_done,

      // --- Clear the flag --- 
      input                               initialize,
      input [NUM_OQ_WIDTH-1:0]            initialize_oq,

      output reg [NUM_OUTPUT_QUEUES-1:0]  empty,


      // --- Misc     
      input                               clk,
      input                               reset
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


   // ------------- Internal parameters --------------


   // ------------- Wires/reg ------------------

   wire                    src_empty;
   wire                    dst_empty;
   reg                     dst_empty_held;

   reg [NUM_OQ_WIDTH-1:0]  dst_oq_held;
   reg [NUM_OQ_WIDTH-1:0]  src_oq_held;

   reg                     dst_num_pkts_in_q_done_held;

   // ------------- Logic ------------------
   assign src_empty = src_num_pkts_in_q == 'h0;
   assign dst_empty = dst_num_pkts_in_q == 'h0;

   always @(posedge clk)
   begin
      if (reset) begin
         empty <= {NUM_OUTPUT_QUEUES{1'b1}};
      end
      else begin
         if (dst_update) begin
            dst_oq_held <= dst_oq;
         end

         if (src_update) begin
            src_oq_held <= src_oq;
         end

         // Update the empty status giving preference to removes over stores
         // since we don't want to accidentally try removing from an empty
         // queue
         if (src_num_pkts_in_q_done) begin
            empty[src_oq_held] <= src_empty;

            dst_num_pkts_in_q_done_held <= dst_num_pkts_in_q_done;
            dst_empty_held <= dst_empty;
         end
         else if (dst_num_pkts_in_q_done) begin
            empty[dst_oq_held] <= dst_empty;
         end
         else if (dst_num_pkts_in_q_done_held) begin
            empty[dst_oq_held] <= dst_empty_held;
         end
         else if (initialize) begin
            empty[initialize_oq] <= 1'b1;
         end
      end
   end

endmodule // oq_regs_eval_empty
