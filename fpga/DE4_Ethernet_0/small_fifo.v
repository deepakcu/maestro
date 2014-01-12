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

`timescale 1ns/1ps

  module small_fifo
    #(parameter WIDTH = 72,
      parameter MAX_DEPTH_BITS = 3,
      parameter PROG_FULL_THRESHOLD = 2**MAX_DEPTH_BITS - 1
      )
    (
		   
     input [WIDTH-1:0] din,     // Data in
     input          wr_en,   // Write enable
     
     input          rd_en,   // Read the next word 
     
     output reg [WIDTH-1:0]  dout,    // Data out
     output         full,
     output         nearly_full,
     output         prog_full,
     output         empty,
     
     input          reset,
     input          clk
     );


localparam MAX_DEPTH        = 2 ** MAX_DEPTH_BITS;
   
reg [WIDTH-1:0] queue [MAX_DEPTH - 1 : 0];
reg [MAX_DEPTH_BITS - 1 : 0] rd_ptr;
reg [MAX_DEPTH_BITS - 1 : 0] wr_ptr;
reg [MAX_DEPTH_BITS : 0] depth;

// Sample the data
always @(posedge clk)
begin
   if (wr_en) 
      queue[wr_ptr] <= din;
   if (rd_en)
      dout <= 
	      // synthesis translate_off
	      #1
	      // synthesis translate_on
	      queue[rd_ptr];
end

always @(posedge clk)
begin
   if (reset) begin
      rd_ptr <= 'h0;
      wr_ptr <= 'h0;
      depth  <= 'h0;
   end
   else begin
      if (wr_en) wr_ptr <= wr_ptr + 'h1;
      if (rd_en) rd_ptr <= rd_ptr + 'h1;
      if (wr_en & ~rd_en) depth <= 
				   // synthesis translate_off
				   #1
				   // synthesis translate_on
				   depth + 'h1;
      else if (~wr_en & rd_en) depth <= 
				   // synthesis translate_off
				   #1
				   // synthesis translate_on
				   depth - 'h1;
   end
end

//assign dout = queue[rd_ptr];
assign full = depth == MAX_DEPTH;
assign prog_full = (depth >= PROG_FULL_THRESHOLD);
assign nearly_full = depth >= MAX_DEPTH-1;
assign empty = depth == 'h0;

// synthesis translate_off
always @(posedge clk)
begin
   if (wr_en && depth == MAX_DEPTH && !rd_en)
      $display($time, " ERROR: Attempt to write to full FIFO: %m");
   if (rd_en && depth == 'h0)
      $display($time, " ERROR: Attempt to read an empty FIFO: %m");
end
// synthesis translate_on

endmodule // small_fifo


/* vim:set shiftwidth=3 softtabstop=3 expandtab: */
