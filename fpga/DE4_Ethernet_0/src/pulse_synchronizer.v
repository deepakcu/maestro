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
  module pulse_synchronizer
    ( input pulse_in_clkA,
      input clkA,
      output pulse_out_clkB,
      input clkB,
      input reset_clkA,
      input reset_clkB
      );

   reg 	    ackA;
   reg 	    ackB;

   reg 	    ackA_synch;
   reg 	    ackA_clkB;
   reg 	    ackB_synch;
   reg 	    ackB_clkA;

   reg 	    pulse_in_clkA_d1;
   reg 	    ackA_clkB_d1;
   reg 	    ackB_d1;

   /* detect rising edges in clkA domain, set the ackA signal
    * until the pulse is acked from the other domain */
   always @(posedge clkA) begin
      if(reset_clkA) begin
	 ackA <= 0;
      end
      else if(!pulse_in_clkA_d1 & pulse_in_clkA) begin
	 ackA <= 1;
      end
      else if(ackB_clkA) begin
	 ackA <= 0;
      end
   end // always @ (posedge clkA)

   /* detect the rising edge of ackA and set ackB until ackA falls */
   always @(posedge clkB) begin
      if(reset_clkB) begin
	 ackB <= 0;
      end
      else if(!ackA_clkB_d1 & ackA_clkB) begin
	 ackB <= 1;
      end
      else if(!ackA_clkB) begin
	 ackB <= 0;
      end
   end // always @ (posedge clkB)

   /* detect rising edge of ackB and send pulse */
   assign pulse_out_clkB = ackB & !ackB_d1;

   /* synchronize the ack signals */
   always @(posedge clkA) begin
      if(reset_clkA) begin
	 pulse_in_clkA_d1 <= 0;
	 ackB_synch <= 0;
	 ackB_clkA <= 0;
      end
      else begin
	 pulse_in_clkA_d1 <= pulse_in_clkA;
	 ackB_synch <= ackB;
	 ackB_clkA <= ackB_synch;
      end
   end

   /* synchronize the ack signals */
   always @(posedge clkB) begin
      if(reset_clkB) begin
	 ackB_d1 <= 0;
	 ackA_synch <= 0;
	 ackA_clkB <= 0;
	 ackA_clkB_d1 <= 0;
      end
      else begin
	 ackB_d1 <= ackB;
	 ackA_synch <= ackA;
	 ackA_clkB <= ackA_synch;
	 ackA_clkB_d1 <= ackA_clkB;
      end
   end

endmodule // pulse_synchronizer
