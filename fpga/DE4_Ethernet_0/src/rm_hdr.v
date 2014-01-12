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
	module rm_hdr
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8
   )
   (
      in_data,
      in_ctrl,
      in_wr,
      in_rdy,

      out_data,
      out_ctrl,
      out_wr,
      out_rdy,
      
      // --- Misc
      reset,
      clk
   );
   
	   input  [DATA_WIDTH-1:0]             in_data;
      input  [CTRL_WIDTH-1:0]             in_ctrl;
      input                               in_wr;
      output                              in_rdy;

      output [DATA_WIDTH-1:0]             out_data;
      output [CTRL_WIDTH-1:0]             out_ctrl;
      output reg                          out_wr;
      input                               out_rdy;
      
      // --- Misc
      input                               reset;
      input                               clk;
	
   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2
   

   // ------------- Regs/ wires -----------

   reg                              in_pkt;
   wire                             fifo_wr;
   wire                             almost_full;
   wire                             empty;


   // ------------ Modules -------------

//   hdr_fifo rm_hdr_fifo
//   (
//      .din({in_ctrl, in_data}),
//      .wr_en(fifo_wr),
//         
//      .dout({out_ctrl, out_data}),
//      .rd_en(out_rdy && !empty),
//         
//      .empty(empty),
//      .full(),
//      .almost_full(almost_full),
//      .rst(reset),
//      .clk(clk)
//   ); xCG
	hdr_fifo	hdr_fifo_inst (
		.aclr (reset),
		.clock (clk),
		.data ({in_ctrl, in_data}),
		.rdreq (out_rdy && !empty),
		.wrreq (fifo_wr),
		.almost_full (almost_full),
		.empty (empty),
		.full (),
		.q ({out_ctrl, out_data})
	);
   

   // ------------- Logic ------------

   // Work out whether we're in a packet or not
   always @(posedge clk) begin
      if (reset)
         in_pkt <= 1'b0;
      else if (in_wr) begin
         if (in_pkt && |in_ctrl)
            in_pkt <= 1'b0;
         else if (!in_pkt && !(|in_ctrl))
            in_pkt <= 1'b1;
      end
   end

   assign fifo_wr = in_wr && (!(|in_ctrl) || in_pkt);

   always @(posedge clk)
      out_wr <= out_rdy && !empty;

   assign in_rdy = !almost_full;

endmodule // rm_hdr
