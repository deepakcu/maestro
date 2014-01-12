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

module reg_grp #(parameter 
      REG_ADDR_BITS = 10,
      NUM_OUTPUTS = 4
   )
   (
      // Upstream register interface
      input                                     reg_req, 
      input                                     reg_rd_wr_L,
      input [REG_ADDR_BITS -1:0]                reg_addr, 
      input [`CPCI_NF2_DATA_WIDTH -1:0]         reg_wr_data,  

      output reg                                reg_ack,  
      output reg [`CPCI_NF2_DATA_WIDTH -1:0]    reg_rd_data,
      
      
      // Downstream register interface
      output [NUM_OUTPUTS - 1 : 0]              local_reg_req,
      output [NUM_OUTPUTS - 1 : 0]              local_reg_rd_wr_L,
      output [NUM_OUTPUTS * (REG_ADDR_BITS - log2(NUM_OUTPUTS)) -1:0] local_reg_addr,
      output [NUM_OUTPUTS * `CPCI_NF2_DATA_WIDTH -1:0] local_reg_wr_data,

      input [NUM_OUTPUTS - 1 : 0]               local_reg_ack,
      input [NUM_OUTPUTS * `CPCI_NF2_DATA_WIDTH -1:0] local_reg_rd_data,
      
      
      //-- misc
      input                                     clk,
      input                                     reset
   );
   
   // Log base 2 function
   //
   // Returns ceil(log2(X))
   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2
   
   // Register addresses
   localparam SWITCH_ADDR_BITS = log2(NUM_OUTPUTS);


   // ===========================================
   // Local variables
   
   wire [SWITCH_ADDR_BITS - 1 : 0]  sel;

   integer i;

   
   // Internal register interface signals
   reg                              int_reg_req[NUM_OUTPUTS - 1 : 0];
   reg                              int_reg_rd_wr_L[NUM_OUTPUTS - 1 : 0];
   reg [REG_ADDR_BITS -1:0]         int_reg_addr[NUM_OUTPUTS - 1 : 0];
   reg [`CPCI_NF2_DATA_WIDTH -1:0]  int_reg_wr_data[NUM_OUTPUTS - 1 : 0];

   wire                             int_reg_ack[NUM_OUTPUTS - 1 : 0];
   wire [`CPCI_NF2_DATA_WIDTH -1:0] int_reg_rd_data[NUM_OUTPUTS - 1 : 0];



   assign sel = reg_addr[REG_ADDR_BITS - 1 : REG_ADDR_BITS - SWITCH_ADDR_BITS];

   // =====================================================
   // Process register requests
   
   always @(posedge clk)
   begin
      for (i = 0; i < NUM_OUTPUTS ; i = i + 1) begin
         if (reset || sel != i) begin
            int_reg_req[i] <= 1'b0;
            int_reg_rd_wr_L[i] <= 1'b0;
            int_reg_addr[i] <= 'h0;
            int_reg_wr_data[i] <= 'h0;
         end
         else begin
            int_reg_req[i] <= reg_req;
            int_reg_rd_wr_L[i] <= reg_rd_wr_L;
            int_reg_addr[i] <= reg_addr;
            int_reg_wr_data[i] <= reg_wr_data;
         end
      end // for
   end

   always @(posedge clk)
   begin
      if (reset || sel >= NUM_OUTPUTS) begin
         // Reset the outputs
         reg_ack <= 1'b0;
         reg_rd_data <= reset ? 'h0 : 'h dead_beef;
      end
      else begin
         reg_ack <= int_reg_ack[sel];
         reg_rd_data <= int_reg_rd_data[sel];
      end
   end

   

   // =====================================================
   // Logic to split/join inputs/outputs

   genvar j;
   generate
      for (j = 0; j < NUM_OUTPUTS ; j = j + 1) begin : flatten
         assign local_reg_req[j] = int_reg_req[j];
         assign local_reg_rd_wr_L[j] = int_reg_rd_wr_L[j];
         assign local_reg_addr[j * (REG_ADDR_BITS - SWITCH_ADDR_BITS) +: (REG_ADDR_BITS - SWITCH_ADDR_BITS)] = int_reg_addr[j];
         assign local_reg_wr_data[j * `CPCI_NF2_DATA_WIDTH +: `CPCI_NF2_DATA_WIDTH] = int_reg_wr_data[j];

         assign int_reg_ack[j] = local_reg_ack[j];
         assign int_reg_rd_data[j] = local_reg_rd_data[j * `CPCI_NF2_DATA_WIDTH +: `CPCI_NF2_DATA_WIDTH];
      end
   endgenerate



   // =====================================================
   // Verify that ack is never high when the request signal is low

   // synthesis translate_off

   integer k;

   always @(posedge clk) begin
      if (reg_req === 1'b0)
         for (k = 0; k < NUM_OUTPUTS ; k = k + 1)
            if (int_reg_ack[k] === 1'b1)
               $display($time, " %m: ERROR: int_reg_ack[%1d] is high when reg_req is low", k);
   end

   // synthesis translate_on

endmodule // reg_grp
   
