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

module jtag_bus
   #( 
     parameter CPCI_NF2_ADDR_WIDTH = 27,
     parameter CPCI_NF2_DATA_WIDTH = 32
   )
   
   (
   // --- These are sigs to/from pins going to CPCI device
   input                                     jtag_rd_wr_L,
	input 												jtag_req,
   input       [CPCI_NF2_ADDR_WIDTH-1:0]     jtag_addr,
   input       [CPCI_NF2_DATA_WIDTH-1:0]     jtag_wr_data,
   output wire     [CPCI_NF2_DATA_WIDTH-1:0]     jtag_rd_data,
	//output wire 										control_port_read_datavalid,
	output reg                             cpci_wr_rdy,
   output /*reg xCG*/                            cpci_rd_rdy,


   // --- Internal signals to/from register rd/wr logic
   //
   output                                 fifo_empty, // functions like a bus_req signal
   input                                  fifo_rd_en,
   output wire                            bus_rd_wr_L,
   output      [CPCI_NF2_ADDR_WIDTH-1:0]  bus_addr,
   output      [CPCI_NF2_DATA_WIDTH-1:0]  bus_wr_data,
   input  wire     [CPCI_NF2_DATA_WIDTH-1:0]  bus_rd_data,
   input                                  bus_rd_vld,
   
   // --- Misc
   input                                  reset,
   input                                  core_clk
);

// --------------------------------------------------------
// Local registers/wires
// --------------------------------------------------------

   // all p2n_* signals are cpci signals registered
   reg p2n_rd_wr_L;
   reg p2n_req;
   reg p2n_req_d1;
   reg [CPCI_NF2_ADDR_WIDTH-1:0] p2n_addr;
   reg [CPCI_NF2_DATA_WIDTH-1:0] p2n_wr_data;
   reg p2n_wr_rdy;
   reg p2n_rd_rdy;

   reg cpci_wr_rdy_nxt;
   reg cpci_rd_rdy_nxt;
   //reg cpci_wr_rdy;
   //reg cpci_rd_rdy;
	
   wire p2n_almost_full;
   wire p2n_prog_full;

   wire [CPCI_NF2_DATA_WIDTH-1:0] n2p_rd_data;
   wire n2p_rd_rdy;
   
   // Read/write enables for the N2P fifo
   wire n2p_rd_en;
   wire n2p_wr_en;


   // Full/empty signals for n2p fifo
   wire n2p_fifo_empty;
   wire n2p_almost_full;

   wire [CPCI_NF2_DATA_WIDTH-1:0]  cpci_rd_data_nxt;


   reg     [CPCI_NF2_DATA_WIDTH-1:0]     jtag_rd_data_reg;
	reg jtag_rd_datavalid_reg;


// -----------------------------------------------------------------
// - Registering of all P2N signals
// -----------------------------------------------------------------

   /* We register everything coming in from the pins so that we have a 
      timing-consistent view of the signals.
         
      Note: the wr_rdy and rd_rdy signals are recorded as we need to be able to
      identify whether the other would have recorded the operation as a success
      or failure
      */   
   always @(posedge core_clk) begin
      p2n_rd_wr_L <= jtag_rd_wr_L;
      p2n_addr    <= jtag_addr;
		p2n_req     <= jtag_req;
      p2n_wr_data <= jtag_wr_data;
		p2n_wr_rdy  <= cpci_wr_rdy;
      p2n_rd_rdy  <= cpci_rd_rdy;
   end
	
	always @(*) begin
		//if (bus_rd_vld) begin
			jtag_rd_data_reg = bus_rd_data;
			jtag_rd_datavalid_reg = bus_rd_vld;
		//end xCG
   end
	
	assign  jtag_rd_data = jtag_rd_data_reg;
	assign  control_port_read_datavalid = jtag_rd_datavalid_reg;
	assign  cpci_rd_rdy = jtag_rd_datavalid_reg; //xCG
/*
-----------------------------------------------------------------
- CPCI -> NF2 requests
-----------------------------------------------------------------
*/

// All requests get funnelled into a 60-bit wide FIFO.
//       60-bits = 32 (data) + 27 (address) + 1 (rd_wr_L) 
// Write in new addr/data when req and wr_rdy are high

// In the current design, the CPCI chip PCI clock period is 30ns, the register
// access interface between the CPCI chip and the NetFPGA chip has clock period 16ns, 
// the NetFPGA chip internal clock period is 8ns.
// The pkt DMA TX is through the register access interface at this moment (to be 
// changed to use the dedicated DMA interface later). So there are a few performance
// requirements:
// 1. When DMA TX is in progress, the register access interface will see register 
//    write requests back to back on two consecutive clock cycles sometimes.
// 2. The reg_grp and the DMA module must finish acking to DMA TX register write request
//    in no more than 3 clock cycles (3 * 8ns = 24ns < 30ns) to prevent the p2n fifo
//    from filling up and overflowing. The DMA TX queue full signal to CPCI chip
//    is currently indicating whether the cpu queue is full, not whether the pci2net_fifo 
//    is full. 


   reg [1:0] p2n_state;
   reg [1:0] p2n_state_nxt;
   
   reg p2n_wr_en;
   wire p2n_full;
   
   localparam
	    P2N_IDLE = 2'h 0,
	    READING = 2'h 1,
	    P2N_RD_DONE = 2'h 2;
   
   // this state machine runs in the pci-clk domain
   always @* begin
      
      // set default values
      p2n_wr_en = 1'b0;
      p2n_state_nxt = p2n_state;
      
      if (reset)
         p2n_state_nxt = P2N_IDLE;
      else begin
         case (p2n_state)
         
            P2N_IDLE: begin
               // Only process the request if the PCI2NET fifo has space for the
               // request
               if (p2n_req && !p2n_full) begin 
                  p2n_wr_en = 1'b1;
                  if (p2n_rd_wr_L) 
                     p2n_state_nxt = READING;

               end   // if
            end // P2N_IDLE
            
            READING: begin
               // Wait until the result is ready to return
               if (p2n_rd_rdy)
                  p2n_state_nxt = P2N_RD_DONE;
            end //READING

            P2N_RD_DONE:
               // Don't return to idle until the other side deasserts the request
               // signal
               if ( ! p2n_req )
                  p2n_state_nxt = P2N_IDLE;
                    
         endcase
      end
   end

   always @(posedge core_clk) begin
      p2n_state <= p2n_state_nxt;      
   end 

 always @*
      if (reset) begin
         cpci_wr_rdy_nxt = 1'b0;
         cpci_rd_rdy_nxt = 1'b0;
      end
      else begin
         cpci_wr_rdy_nxt = !p2n_prog_full;
         //cpci_rd_rdy_nxt = !fifo_empty; xCG, original fifo was in different direction
      end

   always @(posedge core_clk) begin
      //cpci_rd_rdy <= cpci_rd_rdy_nxt; xCG
      cpci_wr_rdy <= cpci_wr_rdy_nxt;
   end 
	
/*
-----------------------------------------------------------------
- NF2 -> CPCI responses
-----------------------------------------------------------------
*/


   // Fifo to cross from the PCI clock domain to the core domain
	/*
   pci2net_16x60 pci2net_fifo (
      .din ({p2n_rd_wr_L, p2n_addr, p2n_wr_data}),
      .rd_clk (core_clk),
      .rd_en (fifo_rd_en),
      .rst (reset),
      .wr_clk (pci_clk),
      .wr_en (p2n_wr_en),
      .almost_full (p2n_almost_full),
      .prog_full (p2n_prog_full),
      .dout ({bus_rd_wr_L, bus_addr, bus_wr_data}),
      .empty (fifo_empty),
      .full (p2n_full)
   );   
*/	
	
	pci2net_16x60	pci2net_fifo (
	.aclr ( reset ),
	.clock ( core_clk ),
	.data ( {p2n_rd_wr_L, p2n_addr, p2n_wr_data} ),
	.rdreq ( fifo_rd_en ),
	.wrreq ( p2n_wr_en ),
	.almost_empty (  ),
	.almost_full ( p2n_prog_full ),
	.empty ( fifo_empty ),
	.full ( p2n_full ),
	.q ( {bus_rd_wr_L, bus_addr, bus_wr_data} ),
	.usedw (  )
	);


// synthesis translate_on

endmodule // cpci_bus
