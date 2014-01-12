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
module unused_reg
   #(
      parameter REG_ADDR_WIDTH = 5
   )
   (
      // Register interface signals
      input                                  reg_req,
      output                                 reg_ack,
      input                                  reg_rd_wr_L,

      input [REG_ADDR_WIDTH - 1:0]           reg_addr,

      output [`CPCI_NF2_DATA_WIDTH - 1:0]    reg_rd_data,
      input [`CPCI_NF2_DATA_WIDTH - 1:0]     reg_wr_data,

      //
      input                                  clk,
      input                                  reset
   );


reg reg_req_d1;

assign reg_rd_data = 'h dead_beef;

// Only generate an ack on a new request
assign reg_ack = reg_req && !reg_req_d1;

always @(posedge clk)
begin
   reg_req_d1 <= reg_req;
end

endmodule // unused_reg
