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
module add_rm_hdr
   #(
	   parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH=DATA_WIDTH/8,
      parameter STAGE_NUMBER = 'hff,
      parameter PORT_NUMBER = 0 
   )
   (
      rx_in_data,
      rx_in_ctrl,
      rx_in_wr,
      rx_in_rdy,
      
      rx_out_data,
      rx_out_ctrl,
      rx_out_wr,
      rx_out_rdy,
      
      tx_in_data,
      tx_in_ctrl,
      tx_in_wr,
      tx_in_rdy,
      
      tx_out_data,
      tx_out_ctrl,
      tx_out_wr,
      tx_out_rdy,
      
      // --- Misc
      reset,
      clk
   );


		
      input [DATA_WIDTH-1:0]              rx_in_data;
      input [CTRL_WIDTH-1:0]              rx_in_ctrl;
      input                               rx_in_wr;
      output                              rx_in_rdy;
      
      output [DATA_WIDTH-1:0]             rx_out_data;
      output [CTRL_WIDTH-1:0]             rx_out_ctrl;
      output                              rx_out_wr;
      input                               rx_out_rdy;
      
      input [DATA_WIDTH-1:0]              tx_in_data;
      input [CTRL_WIDTH-1:0]              tx_in_ctrl;
      input                               tx_in_wr;
      output                              tx_in_rdy;
      
      output [DATA_WIDTH-1:0]             tx_out_data;
      output [CTRL_WIDTH-1:0]             tx_out_ctrl;
      output                              tx_out_wr;
      input                               tx_out_rdy;
      
      // --- Misc
      input                               reset;
      input                               clk;
	
add_hdr
   #(
      .DATA_WIDTH (DATA_WIDTH),
      .CTRL_WIDTH (CTRL_WIDTH),
      .STAGE_NUMBER (STAGE_NUMBER),
      .PORT_NUMBER (PORT_NUMBER)
   ) add_hdr (
      .in_data                            (rx_in_data),
      .in_ctrl                            (rx_in_ctrl),
      .in_wr                              (rx_in_wr),
      .in_rdy                             (rx_in_rdy),
      
      .out_data                           (rx_out_data),
      .out_ctrl                           (rx_out_ctrl),
      .out_wr                             (rx_out_wr),
      .out_rdy                            (rx_out_rdy),
      
      // --- Misc
      .reset                              (reset),
      .clk                                (clk)
   );

   
rm_hdr
   #(
      .DATA_WIDTH (DATA_WIDTH),
      .CTRL_WIDTH (CTRL_WIDTH)
   ) rm_hdr (
      .in_data                            (tx_in_data),
      .in_ctrl                            (tx_in_ctrl),
      .in_wr                              (tx_in_wr),
      .in_rdy                             (tx_in_rdy),

      .out_data                           (tx_out_data),
      .out_ctrl                           (tx_out_ctrl),
      .out_wr                             (tx_out_wr),
      .out_rdy                            (tx_out_rdy),
      
      // --- Misc
      .reset                              (reset),
      .clk                                (clk)
   );

endmodule // add_rm_hdr
