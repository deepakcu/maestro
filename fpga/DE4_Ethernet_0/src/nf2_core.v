///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: nf2_core.v 5145 2009-03-03 01:47:05Z grg $
//
// Module: nf2_core.v
// Project: NetFPGA
// Description: Core module for a NetFPGA design.
//                
// This is instantiated within the nf2_top module. 
// This should contain internal logic only - not I/O buffers or pads.
//
///////////////////////////////////////////////////////////////////////////////
`include "NF_2.1_defines.v"
`include "reg_defines_reference_router.v"
`include "registers.v"
module nf2_core #(
      parameter UDP_REG_SRC_WIDTH = 2,
      parameter WORKER_ADDR_WIDTH = 2, 
      parameter TOTAL_DATA = 8
   )
   (
	
		// JTAG Interface
		
		input  wire [26:0]  control_port_address,   
		input  wire         control_port_read,       
		output wire [31:0]  control_port_readdata,    
		input  wire         control_port_write,      
		input  wire [31:0]  control_port_writedata,  
		output wire         control_port_waitrequest, 
		output wire 		control_port_read_datavalid,
		
		output wire [31:0] 	rxm_port_readdata,
	
		output [7:0]gmac_tx_data_1_out,
		output 		gmac_tx_dvld_1_out,
		input 		gmac_tx_ack_1_out,
		output      end_of_packet_1_out,
		output      start_of_packet_1_out,
		  
		input [7:0] gmac_rx_data_1_in,
		input 		gmac_rx_dvld_1_in,
		input 		gmac_rx_frame_error_1_in, 
		
		output [7:0]gmac_tx_data_2_out,
		output 		gmac_tx_dvld_2_out,
		input 		gmac_tx_ack_2_out,
		output      end_of_packet_2_out,
		output      start_of_packet_2_out,
		  
		input [7:0] gmac_rx_data_2_in,
		input 		gmac_rx_dvld_2_in,
		input 		gmac_rx_frame_error_2_in, 
		
		output [7:0]gmac_tx_data_3_out,
		output 		gmac_tx_dvld_3_out,
		input 		gmac_tx_ack_3_out,
		output      end_of_packet_3_out,
		output      start_of_packet_3_out,
		  
		input [7:0] gmac_rx_data_3_in,
		input 		gmac_rx_dvld_3_in,
		input 		gmac_rx_frame_error_3_in, 
		
		output [7:0]gmac_tx_data_0_out,
		output 		gmac_tx_dvld_0_out,
		input 		gmac_tx_ack_0_out,
		output      end_of_packet_0_out,
		output      start_of_packet_0_out,
		  
		input [7:0] gmac_rx_data_0_in,
		input 		gmac_rx_dvld_0_in,
		input 		gmac_rx_frame_error_0_in, 



 //i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_0_q,
output                 tx_ext_update_0_rdreq,
input                  tx_ext_update_0_empty,
input 		       tx_ext_update_0_almost_full,


//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_1_q,
output                 tx_ext_update_1_rdreq,
input                  tx_ext_update_1_empty,
input 		       tx_ext_update_1_almost_full,


//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_2_q,
output                 tx_ext_update_2_rdreq,
input                  tx_ext_update_2_empty,
input 		       tx_ext_update_2_almost_full,

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_3_q,
output                 tx_ext_update_3_rdreq,
input                  tx_ext_update_3_empty,
input 		       tx_ext_update_3_almost_full,

//i/f b/w op_lut_process_sm.v and RX EXT FIFO
output [63:0]       rx_ext_update_data,

input             rx_ext_update_0_full,
output            rx_ext_update_0_wrreq,
input             rx_ext_update_1_full,
output            rx_ext_update_1_wrreq,
input             rx_ext_update_2_full,
output            rx_ext_update_2_wrreq,
input             rx_ext_update_3_full,
output            rx_ext_update_3_wrreq,
input             rx_ext_update_4_full,
output            rx_ext_update_4_wrreq,
input             rx_ext_update_5_full,
output            rx_ext_update_5_wrreq,
input             rx_ext_update_6_full,
output            rx_ext_update_6_wrreq,
input             rx_ext_update_7_full,
output            rx_ext_update_7_wrreq,

output	      start_update,
output 	      compute_system_reset,
output	      flush_ddr,
output	      start_load,
input [31:0]  iteration_accum_value,

//write interface to DDR (used by load data function)
output [63:0] dram_fifo_writedata,
output        dram_fifo_write,
input         dram_fifo_full,

//read interface from DDR (used by flush data function)
input [63:0]  dram_fifo_readdata,
output        dram_fifo_read,
input         dram_fifo_empty,
output [31:0] num_keys,
output [31:0] log_2_num_workers, //returns the log2(number of workers) - useful for mask calculation in key hashing
output [31:0] shard_id,
output [31:0] max_n_values,
output [31:0] filter_threshold,
output [3:0]    max_fpga_procs,
output	        algo_selection,
output [7:0]  proc_bit_mask,
      // core clock
      input        core_clk_int,
 



      // misc
      input        reset    

   );


	
	
   //------------- local parameters --------------
   localparam DATA_WIDTH = 64;
   localparam CTRL_WIDTH = DATA_WIDTH/8;
   localparam NUM_QUEUES = 8;// deepak try reducing queue number
   localparam PKT_LEN_CNT_WIDTH = 11;
   //---------------- Wires/regs ------------------

   // FIXME
   assign        nf2_err = 1'b 0;

   // Do NOT disable resets
   assign disable_reset = 1'b0;
      
   wire [NUM_QUEUES-1:0]              out_wr;
   wire [NUM_QUEUES-1:0]              out_rdy;
   wire [DATA_WIDTH-1:0]              out_data [NUM_QUEUES-1:0];
   wire [CTRL_WIDTH-1:0]              out_ctrl [NUM_QUEUES-1:0];
   
   wire [NUM_QUEUES-1:0]              in_wr;
   wire [NUM_QUEUES-1:0]              in_rdy;
   wire [DATA_WIDTH-1:0]              in_data [NUM_QUEUES-1:0];
   wire [CTRL_WIDTH-1:0]              in_ctrl [NUM_QUEUES-1:0];

   wire                               wr_0_req;
   wire [`SRAM_ADDR_WIDTH-1:0]        wr_0_addr;
   wire [DATA_WIDTH+CTRL_WIDTH-1:0]   wr_0_data;
   wire                               wr_0_ack;
   
   wire                               rd_0_req;
   wire [`SRAM_ADDR_WIDTH-1:0]        rd_0_addr;
   wire [DATA_WIDTH+CTRL_WIDTH-1:0]   rd_0_data;
   wire                               rd_0_vld;
   wire                               rd_0_ack;
   
   wire [`SRAM_ADDR_WIDTH-1:0]        sram_addr;

   wire [`CPCI_NF2_ADDR_WIDTH-1:0]    cpci_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]    cpci_reg_rd_data;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]    cpci_reg_wr_data;

   wire                                core_reg_req;
   wire                                core_reg_rd_wr_L;
   wire                                core_reg_ack;
   wire [`CORE_REG_ADDR_WIDTH-1:0]     core_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     core_reg_wr_data;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     core_reg_rd_data;
   
   wire [3:0]                          core_4mb_reg_req;
   wire [3:0]                          core_4mb_reg_rd_wr_L;
   wire [3:0]                          core_4mb_reg_ack;
   wire [4 * `BLOCK_SIZE_1M_REG_ADDR_WIDTH-1:0] core_4mb_reg_addr;
   wire [4 * `CPCI_NF2_DATA_WIDTH-1:0] core_4mb_reg_wr_data;
   wire [4 * `CPCI_NF2_DATA_WIDTH-1:0] core_4mb_reg_rd_data;
   
   wire [15:0]                         core_256kb_0_reg_req;
   wire [15:0]                         core_256kb_0_reg_rd_wr_L;
   wire [15:0]                         core_256kb_0_reg_ack;
   wire [16 * `BLOCK_SIZE_64k_REG_ADDR_WIDTH-1:0] core_256kb_0_reg_addr;
   wire [16 * `CPCI_NF2_DATA_WIDTH-1:0] core_256kb_0_reg_wr_data;
   wire [16 * `CPCI_NF2_DATA_WIDTH-1:0] core_256kb_0_reg_rd_data;

   wire                                sram_reg_req;
   wire                                sram_reg_rd_wr_L;
   wire                                sram_reg_ack;
   wire [`SRAM_REG_ADDR_WIDTH-1:0]     sram_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     sram_reg_wr_data; 
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     sram_reg_rd_data;
   
   wire                                udp_reg_req;
   wire                                udp_reg_rd_wr_L;
   wire                                udp_reg_ack;
   wire [`UDP_REG_ADDR_WIDTH-1:0]      udp_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     udp_reg_wr_data;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     udp_reg_rd_data;
   
   wire                                dram_reg_req;
   wire                                dram_reg_rd_wr_L;
   wire                                dram_reg_ack;
   wire [`DRAM_REG_ADDR_WIDTH-1:0]     dram_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     dram_reg_wr_data; 
   wire [`CPCI_NF2_DATA_WIDTH-1:0]     dram_reg_rd_data;
   
   wire [7:0] gmii_txd_int[(NUM_QUEUES / 2) - 1:0];
   wire       gmii_tx_en_int[(NUM_QUEUES / 2) - 1:0];
   wire       gmii_tx_er_int[(NUM_QUEUES / 2) - 1:0];
   wire       gmii_crs_int[(NUM_QUEUES / 2) - 1:0];
   wire       gmii_col_int[(NUM_QUEUES / 2) - 1:0];
   wire [7:0] gmii_rxd_reg[(NUM_QUEUES / 2) - 1:0];
   wire       gmii_rx_dv_reg[(NUM_QUEUES / 2) - 1:0];
   wire       gmii_rx_er_reg[(NUM_QUEUES / 2) - 1:0];
   wire       eth_link_status[(NUM_QUEUES / 2) - 1:0];
   wire [1:0] eth_clock_speed[(NUM_QUEUES / 2) - 1:0];
   wire       eth_duplex_status[(NUM_QUEUES / 2) - 1:0];
   wire       rx_rgmii_clk_int[(NUM_QUEUES / 2) - 1:0];

   wire [`MAC_GRP_REG_ADDR_WIDTH-1:0] mac_grp_reg_addr[3:0];
   wire [3:0]                         mac_grp_reg_req;
   wire [3:0]                         mac_grp_reg_rd_wr_L;
   wire [3:0]                         mac_grp_reg_ack;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]    mac_grp_reg_wr_data[3:0];
   wire [`CPCI_NF2_DATA_WIDTH-1:0]    mac_grp_reg_rd_data[3:0];

   wire [`CPU_QUEUE_REG_ADDR_WIDTH-1:0] cpu_queue_reg_addr[3:0];
   wire [3:0]                         cpu_queue_reg_req;
   wire [3:0]                         cpu_queue_reg_rd_wr_L;
   wire [3:0]                         cpu_queue_reg_ack;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]    cpu_queue_reg_wr_data[3:0];
   wire [`CPCI_NF2_DATA_WIDTH-1:0]    cpu_queue_reg_rd_data[3:0];

   wire [3:0]                         cpu_q_dma_pkt_avail;
   wire [3:0]                         cpu_q_dma_rd;
   wire [`DMA_DATA_WIDTH-1:0]         cpu_q_dma_rd_data [3:0];
   wire [`DMA_CTRL_WIDTH-1:0]         cpu_q_dma_rd_ctrl[3:0];
   
   wire [3:0]                         cpu_q_dma_nearly_full;
   wire [3:0]                         cpu_q_dma_wr;
   wire [`DMA_DATA_WIDTH-1:0]         cpu_q_dma_wr_data[3:0];
   wire [`DMA_CTRL_WIDTH-1:0]         cpu_q_dma_wr_ctrl[3:0];
	
	wire [7:0] 									gmac_tx_data_out[(NUM_QUEUES / 2) - 1:0];
	wire 											gmac_tx_dvld_out[(NUM_QUEUES / 2) - 1:0];
	wire 											gmac_tx_ack_out[(NUM_QUEUES / 2) - 1:0];
	wire [7:0] 									gmac_rx_data_in[(NUM_QUEUES / 2) - 1:0];
	wire 											gmac_rx_dvld_in[(NUM_QUEUES / 2) - 1:0];
	wire 											gmac_rx_frame_error_in[(NUM_QUEUES / 2) - 1:0];
	wire                                end_of_packet[(NUM_QUEUES / 2) - 1:0];
	wire                                start_of_packet[(NUM_QUEUES / 2) - 1:0];
	wire 											tx_rgmii_clk_int;
	
	
	wire jtag_rd_wr_L;
	reg jtag_rd_wr_L_reg;
	//reg control_port_waitrequest_reg;
	reg [31:0] control_port_readdata_reg;
	reg jtag_req_reg;

   //---------------------------------------------
   //
   // MAC rx and tx queues
   //
   //---------------------------------------------

   // Note: uses register block 8-11
   generate
      genvar i;
      for(i=0; i<NUM_QUEUES/2; i=i+1) begin: mac_groups
         nf2_mac_grp #(
            .DATA_WIDTH(DATA_WIDTH), 
            .ENABLE_HEADER(1),
            .PORT_NUMBER(2 * i),
            .STAGE_NUMBER(`IO_QUEUE_STAGE_NUM)
         )
         nf2_mac_grp
           (// register interface
            .mac_grp_reg_req        (core_256kb_0_reg_req[`WORD(`MAC_GRP_0_BLOCK_ADDR + i,1)]),
            .mac_grp_reg_ack        (core_256kb_0_reg_ack[`WORD(`MAC_GRP_0_BLOCK_ADDR + i,1)]),
            .mac_grp_reg_rd_wr_L    (core_256kb_0_reg_rd_wr_L[`WORD(`MAC_GRP_0_BLOCK_ADDR + i,1)]),

            .mac_grp_reg_addr       (core_256kb_0_reg_addr[`WORD(`MAC_GRP_0_BLOCK_ADDR + i,
                                     `BLOCK_SIZE_64k_REG_ADDR_WIDTH)]),

            .mac_grp_reg_rd_data    (core_256kb_0_reg_rd_data[`WORD(`MAC_GRP_0_BLOCK_ADDR + i,
                                     `CPCI_NF2_DATA_WIDTH)]),
            .mac_grp_reg_wr_data    (core_256kb_0_reg_wr_data[`WORD(`MAC_GRP_0_BLOCK_ADDR + i,
                                     `CPCI_NF2_DATA_WIDTH)]),
            // output to data path interface
            .out_wr                 (in_wr[i*2]),
            .out_rdy                (in_rdy[i*2]),
            .out_data               (in_data[i*2]),
            .out_ctrl               (in_ctrl[i*2]),
            // input from data path interface
            .in_wr                  (out_wr[i*2]),
            .in_rdy                 (out_rdy[i*2]),
            .in_data                (out_data[i*2]),
            .in_ctrl                (out_ctrl[i*2]),
            // pins
//            .gmii_tx_d              (gmii_txd_int[i]),
//            .gmii_tx_en             (gmii_tx_en_int[i]),
//            .gmii_tx_er             (gmii_tx_er_int[i]),
//            .gmii_crs               (gmii_crs_int[i]),
//            .gmii_col               (gmii_col_int[i]),
//            .gmii_rx_d              (gmii_rxd_reg[i]),
//            .gmii_rx_dv             (gmii_rx_dv_reg[i]),
//            .gmii_rx_er             (gmii_rx_er_reg[i]),
		
				.gmac_tx_data_out(gmac_tx_data_out[i]),
				.gmac_tx_dvld_out(gmac_tx_dvld_out[i]),
				.gmac_tx_ack_out(gmac_tx_ack_out[i]),
				.end_of_packet(end_of_packet[i]),
		      .start_of_packet(start_of_packet[i]),
		  
				.gmac_rx_data_in(gmac_rx_data_in[i]),
				.gmac_rx_dvld_in(gmac_rx_dvld_in[i]),
				.gmac_rx_frame_error_in(gmac_rx_frame_error_in[i]),
				
            // misc
            .txgmiimiiclk           (tx_rgmii_clk_int),
            .rxgmiimiiclk           (rx_rgmii_clk_int[i]),
            .clk                    (core_clk_int),
            .reset                  (reset)
            );
      end // block: mac_groups
      
   endgenerate

//   //---------------------------------------------
//   //
//   // JTAG interface
//   //
//   //---------------------------------------------
//

		jtag_bus jtag_bus 
		(
			.jtag_rd_wr_L(jtag_rd_wr_L),
			
			.jtag_addr			(control_port_address),
			.jtag_wr_data		(control_port_writedata),
			.jtag_rd_data		(control_port_readdata),
			.jtag_req			(jtag_req),
			.fifo_empty        	(cpci_reg_fifo_empty ),
			.fifo_rd_en        	(cpci_reg_fifo_rd_en ),
			.bus_rd_wr_L       	(cpci_reg_rd_wr_L),
			.bus_addr          	(cpci_reg_addr),
			.bus_wr_data       	(cpci_reg_wr_data),
			.bus_rd_data       	(cpci_reg_rd_data),
			.bus_rd_vld        	(cpci_reg_rd_vld),
			.reset           	(reset),
			.core_clk        	(core_clk_int)
        );

		  always@(*) begin
			if(control_port_read) begin
				jtag_rd_wr_L_reg = 1'b1;
			end
			if(control_port_write) begin
				jtag_rd_wr_L_reg = 1'b0;
			end
		  end
		  
		 always@(control_port_read,control_port_write) begin
			if (reset)begin
				jtag_req_reg = 1'b0;
			end	
			else begin
				if(control_port_read || control_port_write) begin
					jtag_req_reg = 1'b1;
				end
				else 
					jtag_req_reg = 1'b0;
			end	
		 end
		  
		  assign jtag_rd_wr_L = jtag_rd_wr_L_reg;
		  assign jtag_req = jtag_req_reg;
   //-------------------------------------------------
   // User data path
   //-------------------------------------------------

   user_data_path
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .NUM_OUTPUT_QUEUES(NUM_QUEUES),
       .NUM_INPUT_QUEUES(NUM_QUEUES),
       .WORKER_ADDR_WIDTH(WORKER_ADDR_WIDTH),
       .TOTAL_DATA(TOTAL_DATA)) user_data_path
       (.in_data_0 (in_data[0]),
        .in_ctrl_0 (in_ctrl[0]),
        .in_wr_0 (in_wr[0]),
        .in_rdy_0 (in_rdy[0]),

        .in_data_1 (in_data[1]),
        .in_ctrl_1 (in_ctrl[1]),
        .in_wr_1 (in_wr[1]),
        .in_rdy_1 (in_rdy[1]),

        .in_data_2 (in_data[2]),
        .in_ctrl_2 (in_ctrl[2]),
        .in_wr_2 (in_wr[2]),
        .in_rdy_2 (in_rdy[2]),

        .in_data_3 (in_data[3]),
        .in_ctrl_3 (in_ctrl[3]),
        .in_wr_3 (in_wr[3]),
        .in_rdy_3 (in_rdy[3]),
        
        .in_data_4 (in_data[4]),
        .in_ctrl_4 (in_ctrl[4]),
        .in_wr_4 (in_wr[4]),
        .in_rdy_4 (in_rdy[4]),

        .in_data_5 (in_data[5]),
        .in_ctrl_5 (in_ctrl[5]),
        .in_wr_5 (in_wr[5]),
        .in_rdy_5 (in_rdy[5]),

        .in_data_6 (in_data[6]),
        .in_ctrl_6 (in_ctrl[6]),
        .in_wr_6 (in_wr[6]),
        .in_rdy_6 (in_rdy[6]),

        .in_data_7 (in_data[7]),
        .in_ctrl_7 (in_ctrl[7]),
        .in_wr_7 (in_wr[7]),
        .in_rdy_7 (in_rdy[7]),

        /****  not used
         // --- Interface to SATA
         .in_data_5 (in_data[5]),
         .in_ctrl_5 (in_ctrl[5]),
         .in_wr_5 (in_wr[5]),
         .in_rdy_5 (in_rdy[5]),

         // --- Interface to the loopback queue
         .in_data_6 (in_data[6]),
         .in_ctrl_6 (in_ctrl[6]),
         .in_wr_6 (in_wr[6]),
         .in_rdy_6 (in_rdy[6]),

         // --- Interface to a user queue
         .in_data_7 (in_data[7]),
         .in_ctrl_7 (in_ctrl[7]),
         .in_wr_7 (in_wr[7]),
         .in_rdy_7 (in_rdy[7]),
         *****/

			// interface to MAC, CPU tx queues
        .out_data_0 (out_data[0]),
        .out_ctrl_0 (out_ctrl[0]),
        .out_wr_0 (out_wr[0]),
        .out_rdy_0 (out_rdy[0]),
        
        .out_data_1 (out_data[1]),
        .out_ctrl_1 (out_ctrl[1]),
        .out_wr_1 (out_wr[1]),
        .out_rdy_1 (out_rdy[1]),
        
        .out_data_2 (out_data[2]),
        .out_ctrl_2 (out_ctrl[2]),
        .out_wr_2 (out_wr[2]),
        .out_rdy_2 (out_rdy[2]),
        
        .out_data_3 (out_data[3]),
        .out_ctrl_3 (out_ctrl[3]),
        .out_wr_3 (out_wr[3]),
        .out_rdy_3 (out_rdy[3]),
        
        .out_data_4 (out_data[4]),
        .out_ctrl_4 (out_ctrl[4]),
        .out_wr_4 (out_wr[4]),
        .out_rdy_4 (out_rdy[4]),
        
        .out_data_5 (out_data[5]),
        .out_ctrl_5 (out_ctrl[5]),
        .out_wr_5 (out_wr[5]),
        .out_rdy_5 (out_rdy[5]),
        
        .out_data_6 (out_data[6]),
        .out_ctrl_6 (out_ctrl[6]),
        .out_wr_6 (out_wr[6]),
        .out_rdy_6 (out_rdy[6]),
        
        .out_data_7 (out_data[7]),
        .out_ctrl_7 (out_ctrl[7]),
        .out_wr_7 (out_wr[7]),
        .out_rdy_7 (out_rdy[7]),

        /****  not used
         // --- Interface to SATA
         .out_data_5 (out_data[5]),
         .out_ctrl_5 (out_ctrl[5]),
         .out_wr_5 (out_wr[5]),
         .out_rdy_5 (out_rdy[5]),

         // --- Interface to the loopback queue
         .out_data_6 (out_data[6]),
         .out_ctrl_6 (out_ctrl[6]),
         .out_wr_6 (out_wr[6]),
         .out_rdy_6 (out_rdy[6]),

         // --- Interface to a user queue
         .out_data_7 (out_data[7]),
         .out_ctrl_7 (out_ctrl[7]),
         .out_wr_7 (out_wr[7]),
         .out_rdy_7 (out_rdy[7]),
         *****/

        // interface to SRAM
        .wr_0_addr (wr_0_addr),
        .wr_0_req (wr_0_req),
        .wr_0_ack (wr_0_ack),
        .wr_0_data (wr_0_data),
		  
        .rd_0_ack (rd_0_ack),
        .rd_0_data (rd_0_data),
        .rd_0_vld (rd_0_vld),
        .rd_0_addr (rd_0_addr),
        .rd_0_req (rd_0_req),

	//i/f b/w TX EXT FIFO and packet composer
		.tx_ext_update_0_q		(tx_ext_update_0_q),
		.tx_ext_update_0_rdreq		(tx_ext_update_0_rdreq),
		.tx_ext_update_0_empty		(tx_ext_update_0_empty),
	        .tx_ext_update_0_almost_full	(tx_ext_update_0_almost_full),

		//i/f b/w TX EXT FIFO and packet composer
		.tx_ext_update_1_q		(tx_ext_update_1_q),
		.tx_ext_update_1_rdreq		(tx_ext_update_1_rdreq),
		.tx_ext_update_1_empty		(tx_ext_update_1_empty),
	        .tx_ext_update_1_almost_full	(tx_ext_update_1_almost_full),

		//i/f b/w TX EXT FIFO and packet composer
		.tx_ext_update_2_q		(tx_ext_update_2_q),
		.tx_ext_update_2_rdreq		(tx_ext_update_2_rdreq),
		.tx_ext_update_2_empty		(tx_ext_update_2_empty),
	        .tx_ext_update_2_almost_full	(tx_ext_update_2_almost_full),

		//i/f b/w TX EXT FIFO and packet composer
		.tx_ext_update_3_q		(tx_ext_update_3_q),
		.tx_ext_update_3_rdreq		(tx_ext_update_3_rdreq),
		.tx_ext_update_3_empty		(tx_ext_update_3_empty),
	        .tx_ext_update_3_almost_full	(tx_ext_update_3_almost_full),

	//i/f b/w op_lut_process_sm.v and RX EXT FIFO
	.rx_ext_update_data	(rx_ext_update_data),
	.rx_ext_update_0_wrreq	(rx_ext_update_0_wrreq),
	.rx_ext_update_0_full	(rx_ext_update_0_full),
	.rx_ext_update_1_wrreq	(rx_ext_update_1_wrreq),
	.rx_ext_update_1_full	(rx_ext_update_1_full),
	.rx_ext_update_2_wrreq	(rx_ext_update_2_wrreq),
	.rx_ext_update_2_full	(rx_ext_update_2_full),
	.rx_ext_update_3_wrreq	(rx_ext_update_3_wrreq),
	.rx_ext_update_3_full	(rx_ext_update_3_full),
	.rx_ext_update_4_wrreq	(rx_ext_update_4_wrreq),
	.rx_ext_update_4_full	(rx_ext_update_4_full),
	.rx_ext_update_5_wrreq	(rx_ext_update_5_wrreq),
	.rx_ext_update_5_full	(rx_ext_update_5_full),
	.rx_ext_update_6_wrreq	(rx_ext_update_6_wrreq),
	.rx_ext_update_6_full	(rx_ext_update_6_full),
	.rx_ext_update_7_wrreq	(rx_ext_update_7_wrreq),
	.rx_ext_update_7_full	(rx_ext_update_7_full),

        // register interface
        .reg_req                 (udp_reg_req),
        .reg_ack                 (udp_reg_ack),
        .reg_rd_wr_L             (udp_reg_rd_wr_L),
        .reg_addr                (udp_reg_addr),
        .reg_rd_data             (udp_reg_rd_data),
        .reg_wr_data             (udp_reg_wr_data),
       
	.start_update		 (start_update),
 
        .compute_system_reset(compute_system_reset),
	.flush_ddr		 (flush_ddr), 
	.start_load		 (start_load),
	.iteration_accum_value	 (iteration_accum_value),

	//write interface to DDR (used by load data function)
	.dram_fifo_writedata    (dram_fifo_writedata),
	.dram_fifo_write        (dram_fifo_write),
	.dram_fifo_full         (dram_fifo_full),

	//read interface from DDR (used by flush data function)
	.dram_fifo_readdata     (dram_fifo_readdata),
	.dram_fifo_read         (dram_fifo_read),
	.dram_fifo_empty        (dram_fifo_empty),
       
        .num_keys		(num_keys), 
	.log_2_num_workers (log_2_num_workers),
	.shard_id (shard_id),
	.max_n_values (max_n_values),
	.filter_threshold (filter_threshold),
	.max_fpga_procs (max_fpga_procs),
.proc_bit_mask(proc_bit_mask),
	.algo_selection (algo_selection),
	// misc
        .reset (reset),
        .clk (core_clk_int));


   sram	sram_inst 
	(
	.clock 		( core_clk_int ),
	.data 		( wr_0_data ),
	.rdaddress 	( rd_0_addr ),
	.rden 		( rd_0_req ),
	.wraddress 	( wr_0_addr ),
	.wren 		( wr_0_req ),
	.q 			( rd_0_data )
	);

 parameter IDLE_WR_ACK =0, WRITE_WR_ACK = 1;
 parameter IDLE_RD_ACK = 0, READ_RD_ACK = 1;
	
	reg wr_0_ack_next,rd_0_ack_next,rd_0_vld_next;
	reg wr_0_ack_reg,rd_0_ack_reg,rd_0_vld_reg;
	reg [1:0] state_WR_ACK,state_WR_ACK_next;
	reg [1:0] state_RD_ACK,state_RD_ACK_next;
	
	always@(posedge core_clk_int) begin
		if (reset) begin
			wr_0_ack_reg <= 0;
			state_WR_ACK <= IDLE_WR_ACK;
		end
		else begin
			wr_0_ack_reg <= wr_0_ack_next;
			state_WR_ACK <= state_WR_ACK_next;
		end
	end	
		
	always@(posedge core_clk_int) begin
		if (reset) begin
			rd_0_ack_reg <= 0;
			rd_0_vld_reg <= 0;
			state_RD_ACK <= IDLE_RD_ACK;
		end
		else begin
			rd_0_ack_reg <= rd_0_ack_next;
			rd_0_vld_reg <= rd_0_vld_next;
			state_RD_ACK <= state_RD_ACK_next;
		end
	end	
	
	always@(*) begin
		state_WR_ACK_next = state_WR_ACK;
		wr_0_ack_next = wr_0_ack_reg;
		
		case(state_WR_ACK)
		
			IDLE_WR_ACK: begin
				wr_0_ack_next <= 1'b0;
				if(wr_0_req)begin
					state_WR_ACK_next = WRITE_WR_ACK;
				end
			end
			
			WRITE_WR_ACK: begin
				wr_0_ack_next <= 1'b1;
				if(rd_0_req)begin
					state_WR_ACK_next = WRITE_WR_ACK;
				end
				else 
					state_WR_ACK_next = IDLE_WR_ACK;
			end	
			
			default: begin
				state_WR_ACK_next = IDLE_WR_ACK;
			end
			
		endcase
	end
	
	always@(*) begin
		state_RD_ACK_next = state_RD_ACK;
		rd_0_ack_next = rd_0_ack_reg;
		rd_0_vld_next = rd_0_vld_reg;
		
		case(state_RD_ACK)
			IDLE_RD_ACK: begin
				rd_0_ack_next <= 1'b0;
				rd_0_vld_next <= 1'b0;
				if(rd_0_req)begin
					state_RD_ACK_next = READ_RD_ACK;
				end
			end
			
			READ_RD_ACK: begin
				rd_0_ack_next <= 1'b1;
				rd_0_vld_next <= 1'b1;
				if(rd_0_req)begin
					state_RD_ACK_next = READ_RD_ACK;
				end
				else 
					state_RD_ACK_next = IDLE_RD_ACK;
			end	
			
			default: begin
				state_RD_ACK_next = IDLE_RD_ACK;
			end
			
		endcase
	end
	
	assign rd_0_ack = rd_0_ack_reg;
	assign wr_0_ack = wr_0_ack_reg;
	assign rd_0_vld = rd_0_vld_reg;
   //-------------------------------------------------
   //
   // register address decoder, register bus mux and demux 
   //
   //-----------------------------------------------
	
	parameter IDLE_STATE_WAIT = 2'b00,WRITE_STATE_WAIT = 2'b01,READ_STATE_WAIT =2'b10;
	reg [1:0] state_wait,state_wait_next;
	reg control_port_wait_reg,control_port_wait_reg_next;
	reg rxm_port_readdata_valid_reg,rxm_port_readdata_valid_reg_next;
	reg [31:0] rxm_port_readdata_reg;
	reg [31:0] rxm_port_readdata_reg_next;
	
	always@(posedge core_clk_int) begin
		if (reset) begin
			state_wait <= IDLE_STATE_WAIT;
			control_port_wait_reg <= 1'b0;
			rxm_port_readdata_valid_reg <= 1'b0;
			rxm_port_readdata_reg <= 32'b0;
		end
		else begin
			state_wait <= state_wait_next;
			control_port_wait_reg <= control_port_wait_reg_next;
			rxm_port_readdata_valid_reg <= rxm_port_readdata_valid_reg_next;
			rxm_port_readdata_reg <= rxm_port_readdata_reg_next;
		end
	end
	
	always@(*)begin
		state_wait_next = state_wait;
		control_port_wait_reg_next = control_port_wait_reg;
		rxm_port_readdata_valid_reg_next = rxm_port_readdata_valid_reg;
		rxm_port_readdata_reg_next = rxm_port_readdata_reg;
		case (state_wait) 
			IDLE_STATE_WAIT: begin
				rxm_port_readdata_valid_reg_next = 1'b0;
				rxm_port_readdata_reg_next = 32'b0;
				if(control_port_write) begin
					control_port_wait_reg_next = 1'b1;
					state_wait_next = WRITE_STATE_WAIT;
				end
				if(control_port_read) begin
					control_port_wait_reg_next = 1'b1;
					state_wait_next = READ_STATE_WAIT;
				end
			end
			WRITE_STATE_WAIT: begin
				if(out_ack) begin
					control_port_wait_reg_next = 1'b0;
					state_wait_next = IDLE_STATE_WAIT;
				end
			end
			READ_STATE_WAIT: begin
				if(cpci_reg_rd_vld) begin
					control_port_wait_reg_next = 1'b0;
					state_wait_next = IDLE_STATE_WAIT;
					rxm_port_readdata_valid_reg_next = 1'b1;
					rxm_port_readdata_reg_next = control_port_readdata;
				end
			end
		endcase
	end
	
	assign control_port_waitrequest = control_port_wait_reg_next;
	assign control_port_read_datavalid = rxm_port_readdata_valid_reg;
	assign rxm_port_readdata = rxm_port_readdata_reg;
   
   nf2_reg_grp nf2_reg_grp_u 
     (// interface to cpci_bus      
      .fifo_empty        (cpci_reg_fifo_empty),
      .fifo_rd_en        (cpci_reg_fifo_rd_en),
      .bus_rd_wr_L       (cpci_reg_rd_wr_L),
      .bus_addr          (cpci_reg_addr),
      .bus_wr_data       (cpci_reg_wr_data),
      .bus_rd_data       (cpci_reg_rd_data),
      .bus_rd_vld        (cpci_reg_rd_vld),
		.out_ack           (out_ack),

      // interface to core
      .core_reg_req           (core_reg_req),
      .core_reg_rd_wr_L       (core_reg_rd_wr_L),
      .core_reg_addr          (core_reg_addr),
      .core_reg_wr_data       (core_reg_wr_data),
      .core_reg_rd_data       (core_reg_rd_data),
      .core_reg_ack           (core_reg_ack),

      // interface to SRAM
      .sram_reg_req           (sram_reg_req),
      .sram_reg_rd_wr_L       (sram_reg_rd_wr_L),
      .sram_reg_addr          (sram_reg_addr),
      .sram_reg_wr_data       (sram_reg_wr_data),
      .sram_reg_rd_data       (sram_reg_rd_data),
      .sram_reg_ack           (sram_reg_ack),

      // interface to user data path
      .udp_reg_req            (udp_reg_req),
      .udp_reg_rd_wr_L        (udp_reg_rd_wr_L),
      .udp_reg_addr           (udp_reg_addr),
      .udp_reg_wr_data        (udp_reg_wr_data),
      .udp_reg_rd_data        (udp_reg_rd_data),
      .udp_reg_ack            (udp_reg_ack),
      
      // interface to DRAM
      .dram_reg_req           (dram_reg_req),
      .dram_reg_rd_wr_L       (dram_reg_rd_wr_L),
      .dram_reg_addr          (dram_reg_addr),
      .dram_reg_wr_data       (dram_reg_wr_data),
      .dram_reg_rd_data       (dram_reg_rd_data),
      .dram_reg_ack           (dram_reg_ack),

      // misc
      .clk                    (core_clk_int),
      .reset                  (reset)
      
      );


   reg_grp #(
      .REG_ADDR_BITS(`CORE_REG_ADDR_WIDTH),
      .NUM_OUTPUTS(4)
   ) core_4mb_reg_grp
   (
      // Upstream register interface
      .reg_req             (core_reg_req), 
      .reg_rd_wr_L         (core_reg_rd_wr_L),
      .reg_addr            (core_reg_addr), 
      .reg_wr_data         (core_reg_wr_data),  

      .reg_ack             (core_reg_ack),  
      .reg_rd_data         (core_reg_rd_data),
      
      
      // Downstream register interface
      .local_reg_req       (core_4mb_reg_req),
      .local_reg_rd_wr_L   (core_4mb_reg_rd_wr_L),
      .local_reg_addr      (core_4mb_reg_addr),
      .local_reg_wr_data   (core_4mb_reg_wr_data),

      .local_reg_ack       (core_4mb_reg_ack),
      .local_reg_rd_data   (core_4mb_reg_rd_data),
      
      
      //-- misc
      .clk                 (core_clk_int),
      .reset               (reset)
   );

   reg_grp #(
      .REG_ADDR_BITS(`CORE_REG_ADDR_WIDTH - 2),
      .NUM_OUTPUTS(16)
   ) core_256kb_0_reg_grp
   (
      // Upstream register interface
      .reg_req             (core_4mb_reg_req[`WORD(1,1)]), 
      .reg_ack             (core_4mb_reg_ack[`WORD(1,1)]),  
      .reg_rd_wr_L         (core_4mb_reg_rd_wr_L[`WORD(1,1)]),
      .reg_addr            (core_4mb_reg_addr[`WORD(1, `BLOCK_SIZE_1M_REG_ADDR_WIDTH)]), 

      .reg_rd_data         (core_4mb_reg_rd_data[`WORD(1, `CPCI_NF2_DATA_WIDTH)]),
      .reg_wr_data         (core_4mb_reg_wr_data[`WORD(1, `CPCI_NF2_DATA_WIDTH)]),  
      
      
      // Downstream register interface
      .local_reg_req       (core_256kb_0_reg_req),
      .local_reg_rd_wr_L   (core_256kb_0_reg_rd_wr_L),
      .local_reg_addr      (core_256kb_0_reg_addr),
      .local_reg_wr_data   (core_256kb_0_reg_wr_data),

      .local_reg_ack       (core_256kb_0_reg_ack),
      .local_reg_rd_data   (core_256kb_0_reg_rd_data),
      
      
      //-- misc
      .clk                 (core_clk_int),
      .reset               (reset)
   );

   //--------------------------------------------------
   //
   // --- Device ID register
   //
   //     Provides a set of registers to uniquely identify the design
   //     - Design/Device ID
   //     - Revision
   //     - Description
   //
   //--------------------------------------------------

   device_id_reg 
`ifdef DEVICE_ID
   #(
      .DEVICE_ID(`DEVICE_ID),
      .REVISION(`DEVICE_REVISION),
      .DEVICE_STR(`DEVICE_STR)
   ) 
`endif
   device_id_reg (
      // Register interface signals
      .reg_req          (core_256kb_0_reg_req[`WORD(`DEV_ID_BLOCK_ADDR,1)]),
      .reg_ack          (core_256kb_0_reg_ack[`WORD(`DEV_ID_BLOCK_ADDR,1)]),
      .reg_rd_wr_L      (core_256kb_0_reg_rd_wr_L[`WORD(`DEV_ID_BLOCK_ADDR,1)]),
      .reg_addr         (core_256kb_0_reg_addr[`WORD(`DEV_ID_BLOCK_ADDR,`DEV_ID_REG_ADDR_WIDTH)]),
      .reg_rd_data      (core_256kb_0_reg_rd_data[`WORD(`DEV_ID_BLOCK_ADDR,`CPCI_NF2_DATA_WIDTH)]),
      .reg_wr_data      (core_256kb_0_reg_wr_data[`WORD(`DEV_ID_BLOCK_ADDR,`CPCI_NF2_DATA_WIDTH)]),

      //
      .clk              (core_clk_int),
      .reset            (reset)
   );




   //--------------------------------------------------
   //
   // --- Unused register signals
   //
   //--------------------------------------------------

   unused_reg #(
      .REG_ADDR_WIDTH(`BLOCK_SIZE_1M_REG_ADDR_WIDTH)
   ) unused_reg_core_4mb_0 (
      // Register interface signals
      .reg_req             (core_4mb_reg_req[`WORD(0,1)]), 
      .reg_ack             (core_4mb_reg_ack[`WORD(0,1)]),  
      .reg_rd_wr_L         (core_4mb_reg_rd_wr_L[`WORD(0,1)]),
      .reg_addr            (core_4mb_reg_addr[`WORD(0, `BLOCK_SIZE_1M_REG_ADDR_WIDTH)]), 

      .reg_rd_data         (core_4mb_reg_rd_data[`WORD(0, `CPCI_NF2_DATA_WIDTH)]),
      .reg_wr_data         (core_4mb_reg_wr_data[`WORD(0, `CPCI_NF2_DATA_WIDTH)]),  

      //
      .clk           (core_clk_int),
      .reset         (reset)
   );

   unused_reg #(
      .REG_ADDR_WIDTH(`BLOCK_SIZE_1M_REG_ADDR_WIDTH)
   ) unused_reg_core_4mb_2 (
      // Register interface signals
      .reg_req             (core_4mb_reg_req[`WORD(2,1)]), 
      .reg_ack             (core_4mb_reg_ack[`WORD(2,1)]),  
      .reg_rd_wr_L         (core_4mb_reg_rd_wr_L[`WORD(2,1)]),
      .reg_addr            (core_4mb_reg_addr[`WORD(2, `BLOCK_SIZE_1M_REG_ADDR_WIDTH)]), 

      .reg_rd_data         (core_4mb_reg_rd_data[`WORD(2, `CPCI_NF2_DATA_WIDTH)]),
      .reg_wr_data         (core_4mb_reg_wr_data[`WORD(2, `CPCI_NF2_DATA_WIDTH)]),  

      //
      .clk           (core_clk_int),
      .reset         (reset)
   );

   unused_reg #(
      .REG_ADDR_WIDTH(`BLOCK_SIZE_1M_REG_ADDR_WIDTH)
   ) unused_reg_core_4mb_3 (
      // Register interface signals
      .reg_req             (core_4mb_reg_req[`WORD(3,1)]), 
      .reg_ack             (core_4mb_reg_ack[`WORD(3,1)]),  
      .reg_rd_wr_L         (core_4mb_reg_rd_wr_L[`WORD(3,1)]),
      .reg_addr            (core_4mb_reg_addr[`WORD(3, `BLOCK_SIZE_1M_REG_ADDR_WIDTH)]), 

      .reg_rd_data         (core_4mb_reg_rd_data[`WORD(3, `CPCI_NF2_DATA_WIDTH)]),
      .reg_wr_data         (core_4mb_reg_wr_data[`WORD(3, `CPCI_NF2_DATA_WIDTH)]),  

      //
      .clk           (core_clk_int),
      .reset         (reset)
   );

   generate
      //genvar i;
      for (i = 0; i < 16; i = i + 1) begin: unused_reg_core_256kb_0 
         if (!(i >= `MAC_GRP_0_BLOCK_ADDR && 
               i <  `MAC_GRP_0_BLOCK_ADDR + NUM_QUEUES/2) && 
             !(i >= `CPU_QUEUE_0_BLOCK_ADDR && 
               i <  `CPU_QUEUE_0_BLOCK_ADDR + NUM_QUEUES/2) && 
             i != `DEV_ID_BLOCK_ADDR && 
             i != `DMA_BLOCK_ADDR && 
             i != `MDIO_BLOCK_ADDR) 
            unused_reg #(
               .REG_ADDR_WIDTH(`BLOCK_SIZE_64k_REG_ADDR_WIDTH)
            ) unused_reg_core_256kb_0_x (
               // Register interface signals
               .reg_req             (core_256kb_0_reg_req[`WORD(i,1)]), 
               .reg_ack             (core_256kb_0_reg_ack[`WORD(i,1)]),  
               .reg_rd_wr_L         (core_256kb_0_reg_rd_wr_L[`WORD(i,1)]),
               .reg_addr            (core_256kb_0_reg_addr[`WORD(i, `BLOCK_SIZE_64k_REG_ADDR_WIDTH)]), 

               .reg_rd_data         (core_256kb_0_reg_rd_data[`WORD(i, `CPCI_NF2_DATA_WIDTH)]),
               .reg_wr_data         (core_256kb_0_reg_wr_data[`WORD(i, `CPCI_NF2_DATA_WIDTH)]),  

               //
               .clk           (core_clk_int),
               .reset         (reset)
            );
      end
   endgenerate


	  assign        tx_rgmii_clk_int = core_clk_int;
      assign        rx_rgmii_0_clk_int = core_clk_int;
      assign        rx_rgmii_1_clk_int = core_clk_int;
      assign        rx_rgmii_2_clk_int = core_clk_int;
      assign        rx_rgmii_3_clk_int = core_clk_int;
	

	
		assign gmac_tx_data_0_out = gmac_tx_data_out[0];
		assign gmac_tx_dvld_0_out = gmac_tx_dvld_out[0];
		assign gmac_tx_ack_out[0]  = gmac_tx_ack_0_out;
		assign end_of_packet_0_out = end_of_packet[0];
		assign start_of_packet_0_out = start_of_packet[0];
		
		  
		assign gmac_rx_data_in[0]					=	gmac_rx_data_0_in;
		assign gmac_rx_dvld_in[0] 					=	gmac_rx_dvld_0_in;
		assign gmac_rx_frame_error_in[0] 			=	gmac_rx_frame_error_0_in; 
		
		assign gmac_tx_data_1_out 					= 	gmac_tx_data_out[1];
		assign gmac_tx_dvld_1_out 					= 	gmac_tx_dvld_out[1];
		assign gmac_tx_ack_out[1]  					= 	gmac_tx_ack_1_out;
		assign end_of_packet_1_out 					= 	end_of_packet[1];
		assign start_of_packet_1_out 				= 	start_of_packet[1];
		  
		assign gmac_rx_data_in[1]					=	gmac_rx_data_1_in;
		assign gmac_rx_dvld_in[1] 					=	gmac_rx_dvld_1_in;
		assign gmac_rx_frame_error_in[1] 			=	gmac_rx_frame_error_1_in; 
		
		assign gmac_tx_data_2_out 					= 	gmac_tx_data_out[2];
		assign gmac_tx_dvld_2_out 					= 	gmac_tx_dvld_out[2];
		assign gmac_tx_ack_out[2]  					= 	gmac_tx_ack_2_out;
		assign end_of_packet_2_out 					= 	end_of_packet[2];
		assign start_of_packet_2_out 				= 	start_of_packet[2];
		  
		assign gmac_rx_data_in[2]					=	gmac_rx_data_2_in;
		assign gmac_rx_dvld_in[2] 					=	gmac_rx_dvld_2_in;
		assign gmac_rx_frame_error_in[2] 			=	gmac_rx_frame_error_2_in; 
		
		assign gmac_tx_data_3_out 					= 	gmac_tx_data_out[3];
		assign gmac_tx_dvld_3_out 					= 	gmac_tx_dvld_out[3];
		assign gmac_tx_ack_out[3]  					= 	gmac_tx_ack_3_out;
		assign end_of_packet_3_out 					= 	end_of_packet[3];
		assign start_of_packet_3_out 				=	start_of_packet[3];
		  
		assign gmac_rx_data_in[3]					=	gmac_rx_data_3_in;
		assign gmac_rx_dvld_in[3] 					=	gmac_rx_dvld_3_in;
		assign gmac_rx_frame_error_in[3] 			=	gmac_rx_frame_error_3_in; 
	

	

   assign rx_rgmii_clk_int[0]    = rx_rgmii_0_clk_int;
   assign rx_rgmii_clk_int[1]    = rx_rgmii_1_clk_int;
   assign rx_rgmii_clk_int[2]    = rx_rgmii_2_clk_int;
   assign rx_rgmii_clk_int[3]    = rx_rgmii_3_clk_int;

endmodule // nf2_core
