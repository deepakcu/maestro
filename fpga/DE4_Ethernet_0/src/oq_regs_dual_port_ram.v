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
//include "registers.v"

module oq_regs_dual_port_ram
   #(
      parameter REG_WIDTH = `CPCI_NF2_DATA_WIDTH,
      parameter NUM_OUTPUT_QUEUES = 8,
      parameter REG_FILE_ADDR_WIDTH = log2(NUM_OUTPUT_QUEUES)
   )
   (
      input [REG_FILE_ADDR_WIDTH-1:0]     addr_a,
      input                               we_a,
      input [REG_WIDTH-1:0]               din_a,
      output reg [REG_WIDTH-1:0]          dout_a,
      input                               clk_a,

      input [REG_FILE_ADDR_WIDTH-1:0]     addr_b,
      input                               we_b,
      input [REG_WIDTH-1:0]               din_b,
      output reg [REG_WIDTH-1:0]          dout_b,
      input                               clk_b
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

   // Uncomment the following synthesis attribute to force the memory into
   // Block RAM.
   //
   // Note: The attribute must appear immediately above the RAM register
   // declaraion.
   //
   (* ram_style = "block" *)
   reg [REG_WIDTH-1:0]      ram[0:NUM_OUTPUT_QUEUES-1];

   always @(posedge clk_a) begin
      if (we_a)
         ram[addr_a] <= din_a;

      dout_a <= ram[addr_a];
   end

   always @(posedge clk_b) begin
      if (we_b)
         ram[addr_b] <= din_b;

      dout_b <= ram[addr_b];
   end

endmodule // oq_dual_port_num
