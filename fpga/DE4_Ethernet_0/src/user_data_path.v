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
	module user_data_path
  #(
	 parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH=DATA_WIDTH/8,
    parameter UDP_REG_SRC_WIDTH = 2,
    parameter NUM_OUTPUT_QUEUES = 8,
    parameter NUM_INPUT_QUEUES = 8,
    parameter SRAM_DATA_WIDTH = DATA_WIDTH+CTRL_WIDTH,
    parameter SRAM_ADDR_WIDTH = 19,
    parameter WORKER_ADDR_WIDTH = 2,
    parameter TOTAL_DATA = 8
	 )

   (
    in_data_0,
    in_ctrl_0,
    in_wr_0,
    in_rdy_0,

    in_data_1,
    in_ctrl_1,
    in_wr_1,
    in_rdy_1,

    in_data_2,
    in_ctrl_2,
    in_wr_2,
    in_rdy_2,

    in_data_3,
    in_ctrl_3,
    in_wr_3,
    in_rdy_3,

    in_data_4,
    in_ctrl_4,
    in_wr_4,
    in_rdy_4,

    in_data_5,
    in_ctrl_5,
    in_wr_5,
    in_rdy_5,

    in_data_6,
    in_ctrl_6,
    in_wr_6,
    in_rdy_6,

    in_data_7,
    in_ctrl_7,
    in_wr_7,
    in_rdy_7,

/****  not used
    // --- Interface to SATA
    input  [DATA_WIDTH-1:0]            in_data_5,
    input  [CTRL_WIDTH-1:0]            in_ctrl_5,
    input                              in_wr_5,
    output                             in_rdy_5,

    // --- Interface to the loopback queue
    input  [DATA_WIDTH-1:0]            in_data_6,
    input  [CTRL_WIDTH-1:0]            in_ctrl_6,
    input                              in_wr_6,
    output                             in_rdy_6,

    // --- Interface to a user queue
    input  [DATA_WIDTH-1:0]            in_data_7,
    input  [CTRL_WIDTH-1:0]            in_ctrl_7,
    input                              in_wr_7,
    output                             in_rdy_7,
*****/

    out_data_0,
    out_ctrl_0,
    out_wr_0,
    out_rdy_0,

    out_data_1,
    out_ctrl_1,
    out_wr_1,
    out_rdy_1,

    out_data_2,
    out_ctrl_2,
    out_wr_2,
    out_rdy_2,

    out_data_3,
    out_ctrl_3,
    out_wr_3,
    out_rdy_3,

    out_data_4,
    out_ctrl_4,
    out_wr_4,
    out_rdy_4,

    out_data_5,
    out_ctrl_5,
    out_wr_5,
    out_rdy_5,

    out_data_6,
    out_ctrl_6,
    out_wr_6,
    out_rdy_6,

    out_data_7,
    out_ctrl_7,
    out_wr_7,
    out_rdy_7,

/****  not used
    // --- Interface to SATA
    output  [DATA_WIDTH-1:0]           out_data_5,
    output  [CTRL_WIDTH-1:0]           out_ctrl_5,
    output                             out_wr_5,
    input                              out_rdy_5,

    // --- Interface to the loopback queue
    output  [DATA_WIDTH-1:0]           out_data_6,
    output  [CTRL_WIDTH-1:0]           out_ctrl_6,
    output                             out_wr_6,
    input                              out_rdy_6,

    // --- Interface to a user queue
    output  [DATA_WIDTH-1:0]           out_data_7,
    output  [CTRL_WIDTH-1:0]           out_ctrl_7,
    output                             out_wr_7,
    input                              out_rdy_7,
*****/

     // interface to SRAM
     wr_0_addr,
     wr_0_req,
     wr_0_ack,
     wr_0_data,
     
     rd_0_ack,
     rd_0_data,
     rd_0_vld,
     rd_0_addr,
     rd_0_req,

     // interface to DRAM
     /* TBD */

     // register interface
     reg_req,
     reg_ack,
     reg_rd_wr_L,
     reg_addr,
     reg_rd_data,
     reg_wr_data,
	  
  
     //i/f b/w TX EXT FIFO and packet composer
     tx_ext_update_0_q,
     tx_ext_update_0_rdreq,
     tx_ext_update_0_empty,
     tx_ext_update_0_almost_full,

     //i/f b/w TX EXT FIFO and packet composer
     tx_ext_update_1_q,
     tx_ext_update_1_rdreq,
     tx_ext_update_1_empty,
     tx_ext_update_1_almost_full,

     //i/f b/w TX EXT FIFO and packet composer
     tx_ext_update_2_q,
     tx_ext_update_2_rdreq,
     tx_ext_update_2_empty,
     tx_ext_update_2_almost_full,

     //i/f b/w TX EXT FIFO and packet composer
     tx_ext_update_3_q,
     tx_ext_update_3_rdreq,
     tx_ext_update_3_empty,
     tx_ext_update_3_almost_full,


//i/f b/w op_lut_process_sm.v and RX EXT FIFO
     rx_ext_update_data,

     rx_ext_update_0_full,
     rx_ext_update_0_wrreq,
     rx_ext_update_1_full,
     rx_ext_update_1_wrreq,
     rx_ext_update_2_full,
     rx_ext_update_2_wrreq,
     rx_ext_update_3_full,
     rx_ext_update_3_wrreq,
     rx_ext_update_4_full,
     rx_ext_update_4_wrreq,
     rx_ext_update_5_full,
     rx_ext_update_5_wrreq,
     rx_ext_update_6_full,
     rx_ext_update_6_wrreq,
     rx_ext_update_7_full,
     rx_ext_update_7_wrreq,


     start_update,
     compute_system_reset,
     flush_ddr,
     start_load,
	  iteration_accum_value,

	  dram_fifo_writedata,
     dram_fifo_write,
     dram_fifo_full,

     //read interface from DDR (used by flush data function)
     dram_fifo_readdata,
     dram_fifo_read,
     dram_fifo_empty,

     num_keys,
     log_2_num_workers, //returns the log2(number of workers) - useful for mask calculation in key hashing
     shard_id,
     max_n_values,
     filter_threshold,

    max_fpga_procs,
    algo_selection,
    proc_bit_mask,
	  
     // misc
     reset,
     clk
	  );
	  

    output start_update;
    output flush_ddr;
    output start_load;    
    output compute_system_reset;

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_0_q;
output                 tx_ext_update_0_rdreq;
input                  tx_ext_update_0_empty;
input 		       tx_ext_update_0_almost_full;


//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_1_q;
output                 tx_ext_update_1_rdreq;
input                  tx_ext_update_1_empty;
input 		       tx_ext_update_1_almost_full;


//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_2_q;
output                 tx_ext_update_2_rdreq;
input                  tx_ext_update_2_empty;
input 		       tx_ext_update_2_almost_full;

//i/f b/w TX EXT FIFO and packet composer
input  [63:0]          tx_ext_update_3_q;
output                 tx_ext_update_3_rdreq;
input                  tx_ext_update_3_empty;
input 		       tx_ext_update_3_almost_full;


//i/f b/w op_lut_process_sm.v and RX EXT FIFO
output [63:0]       rx_ext_update_data;

input               rx_ext_update_0_full;
output              rx_ext_update_0_wrreq;
input               rx_ext_update_1_full;
output              rx_ext_update_1_wrreq;
input               rx_ext_update_2_full;
output              rx_ext_update_2_wrreq;
input               rx_ext_update_3_full;
output              rx_ext_update_3_wrreq;
input               rx_ext_update_4_full;
output              rx_ext_update_4_wrreq;
input               rx_ext_update_5_full;
output              rx_ext_update_5_wrreq;
input               rx_ext_update_6_full;
output              rx_ext_update_6_wrreq;
input               rx_ext_update_7_full;
output              rx_ext_update_7_wrreq;

    input  [DATA_WIDTH-1:0]            in_data_0;
    input  [CTRL_WIDTH-1:0]            in_ctrl_0;
    input                              in_wr_0;
    output                             in_rdy_0;

    input  [DATA_WIDTH-1:0]            in_data_1;
    input  [CTRL_WIDTH-1:0]            in_ctrl_1;
    input                              in_wr_1;
    output                             in_rdy_1;

    input  [DATA_WIDTH-1:0]            in_data_2;
    input  [CTRL_WIDTH-1:0]            in_ctrl_2;
    input                              in_wr_2;
    output                             in_rdy_2;

    input  [DATA_WIDTH-1:0]            in_data_3;
    input  [CTRL_WIDTH-1:0]            in_ctrl_3;
    input                              in_wr_3;
    output                             in_rdy_3;

    input  [DATA_WIDTH-1:0]            in_data_4;
    input  [CTRL_WIDTH-1:0]            in_ctrl_4;
    input                              in_wr_4;
    output                             in_rdy_4;

    input  [DATA_WIDTH-1:0]            in_data_5;
    input  [CTRL_WIDTH-1:0]            in_ctrl_5;
    input                              in_wr_5;
    output                             in_rdy_5;

    input  [DATA_WIDTH-1:0]            in_data_6;
    input  [CTRL_WIDTH-1:0]            in_ctrl_6;
    input                              in_wr_6;
    output                             in_rdy_6;

    input  [DATA_WIDTH-1:0]            in_data_7;
    input  [CTRL_WIDTH-1:0]            in_ctrl_7;
    input                              in_wr_7;
    output                             in_rdy_7;

/****  not used
    // --- Interface to SATA
    input  [DATA_WIDTH-1:0]            in_data_5,
    input  [CTRL_WIDTH-1:0]            in_ctrl_5,
    input                              in_wr_5,
    output                             in_rdy_5,

    // --- Interface to the loopback queue
    input  [DATA_WIDTH-1:0]            in_data_6,
    input  [CTRL_WIDTH-1:0]            in_ctrl_6,
    input                              in_wr_6,
    output                             in_rdy_6,

    // --- Interface to a user queue
    input  [DATA_WIDTH-1:0]            in_data_7,
    input  [CTRL_WIDTH-1:0]            in_ctrl_7,
    input                              in_wr_7,
    output                             in_rdy_7,
*****/

    output  [DATA_WIDTH-1:0]           out_data_0;
    output  [CTRL_WIDTH-1:0]           out_ctrl_0;
    output                             out_wr_0;
    input                              out_rdy_0;

    output  [DATA_WIDTH-1:0]           out_data_1;
    output  [CTRL_WIDTH-1:0]           out_ctrl_1;
    output                             out_wr_1;
    input                              out_rdy_1;

    output  [DATA_WIDTH-1:0]           out_data_2;
    output  [CTRL_WIDTH-1:0]           out_ctrl_2;
    output                             out_wr_2;
    input                              out_rdy_2;

    output  [DATA_WIDTH-1:0]           out_data_3;
    output  [CTRL_WIDTH-1:0]           out_ctrl_3;
    output                             out_wr_3;
    input                              out_rdy_3;

    output  [DATA_WIDTH-1:0]           out_data_4;
    output  [CTRL_WIDTH-1:0]           out_ctrl_4;
    output                             out_wr_4;
    input                              out_rdy_4;

    output  [DATA_WIDTH-1:0]           out_data_5;
    output  [CTRL_WIDTH-1:0]           out_ctrl_5;
    output                             out_wr_5;
    input                              out_rdy_5;

    output  [DATA_WIDTH-1:0]           out_data_6;
    output  [CTRL_WIDTH-1:0]           out_ctrl_6;
    output                             out_wr_6;
    input                              out_rdy_6;

    output  [DATA_WIDTH-1:0]           out_data_7;
    output  [CTRL_WIDTH-1:0]           out_ctrl_7;
    output                             out_wr_7;
    input                              out_rdy_7;

/****  not used
    // --- Interface to SATA
    output  [DATA_WIDTH-1:0]           out_data_5,
    output  [CTRL_WIDTH-1:0]           out_ctrl_5,
    output                             out_wr_5,
    input                              out_rdy_5,

    // --- Interface to the loopback queue
    output  [DATA_WIDTH-1:0]           out_data_6,
    output  [CTRL_WIDTH-1:0]           out_ctrl_6,
    output                             out_wr_6,
    input                              out_rdy_6,

    // --- Interface to a user queue
    output  [DATA_WIDTH-1:0]           out_data_7,
    output  [CTRL_WIDTH-1:0]           out_ctrl_7,
    output                             out_wr_7,
    input                              out_rdy_7,
*****/

     // interface to SRAM
     output [SRAM_ADDR_WIDTH-1:0]       wr_0_addr;
     output                             wr_0_req;
     input                              wr_0_ack;
     output [SRAM_DATA_WIDTH-1:0]       wr_0_data;
     
     input                              rd_0_ack;
     input  [SRAM_DATA_WIDTH-1:0]       rd_0_data;
     input                              rd_0_vld;
     output [SRAM_ADDR_WIDTH-1:0]       rd_0_addr;
     output                             rd_0_req;

     // interface to DRAM
     /* TBD */

     // register interface
     input                              reg_req;
     output                             reg_ack;
     input                              reg_rd_wr_L;
     input [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr;
     output [`CPCI_NF2_DATA_WIDTH-1:0]  reg_rd_data;
     input [`CPCI_NF2_DATA_WIDTH-1:0]   reg_wr_data;
  
     output [31:0]			num_keys;
     output [31:0]                      log_2_num_workers;
     output [31:0]			shard_id;
     output [31:0]			max_n_values;
     output [31:0]                      filter_threshold;
     output [3:0]    			max_fpga_procs;
     output	        		algo_selection;


     // misc
     input                              reset;
     input                              clk;
     input [31:0]			iteration_accum_value;

     //write interface to DDR (used by load data function) 
     output [63:0] dram_fifo_writedata;
     output        dram_fifo_write;
     input         dram_fifo_full;

     //read interface from DDR (used by flush data function)
     input [63:0]  dram_fifo_readdata;
     output        dram_fifo_read;
     input         dram_fifo_empty;

    output [7:0]  proc_bit_mask;
	  
   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   //---------- Internal parameters -----------

   localparam NUM_IQ_BITS = log2(NUM_INPUT_QUEUES);
   
   localparam IN_ARB_STAGE_NUM = 2;
   localparam OP_LUT_STAGE_NUM = 4;
   localparam OQ_STAGE_NUM     = 6;
   
   //-------- Input arbiter wires/regs ------- 
   wire                             in_arb_in_reg_req;
   wire                             in_arb_in_reg_ack;
   wire                             in_arb_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   in_arb_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  in_arb_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     in_arb_in_reg_src;

   //------- output port lut wires/regs ------
   wire [CTRL_WIDTH-1:0]            op_lut_in_ctrl;
   wire [DATA_WIDTH-1:0]            op_lut_in_data;
   wire                             op_lut_in_wr;
   wire                             op_lut_in_rdy;

   wire                             op_lut_in_reg_req;
   wire                             op_lut_in_reg_ack;
   wire                             op_lut_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   op_lut_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  op_lut_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     op_lut_in_reg_src;

   wire [CTRL_WIDTH-1:0]            oq_in_ctrl;
   wire [DATA_WIDTH-1:0]            oq_in_data;
   wire                             oq_in_wr;
   wire                             oq_in_rdy;

   wire                             oq_in_reg_req;
   wire                             oq_in_reg_ack;
   wire                             oq_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   oq_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  oq_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     oq_in_reg_src;

   //-------- UDP register master wires/regs ------- 
   wire                             udp_reg_req_in;
   wire                             udp_reg_ack_in;
   wire                             udp_reg_rd_wr_L_in;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   udp_reg_addr_in;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  udp_reg_data_in;
   wire [UDP_REG_SRC_WIDTH-1:0]     udp_reg_src_in;

   wire 			    check_terminate;
   wire [31:0]			    interpkt_gap_cycles;
   //--------- Connect the data path -----------
   
   input_arbiter
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .STAGE_NUMBER(IN_ARB_STAGE_NUM))
   input_arbiter
     (
    .out_data             (op_lut_in_data),
    .out_ctrl             (op_lut_in_ctrl),
    .out_wr               (op_lut_in_wr),
    .out_rdy              (op_lut_in_rdy),
                          
      // --- Interface to the input queues
    .in_data_0            (in_data_0),
    .in_ctrl_0            (in_ctrl_0),
    .in_wr_0              (in_wr_0),
    .in_rdy_0             (in_rdy_0),
                          
    .in_data_1            (in_data_1),
    .in_ctrl_1            (in_ctrl_1),
    .in_wr_1              (in_wr_1),
    .in_rdy_1             (in_rdy_1),
                          
    .in_data_2            (in_data_2),
    .in_ctrl_2            (in_ctrl_2),
    .in_wr_2              (in_wr_2),
    .in_rdy_2             (in_rdy_2),
                          
    .in_data_3            (in_data_3),
    .in_ctrl_3            (in_ctrl_3),
    .in_wr_3              (in_wr_3),
    .in_rdy_3             (in_rdy_3),
                          
    .in_data_4            (in_data_4),
    .in_ctrl_4            (in_ctrl_4),
    .in_wr_4              (in_wr_4),
    .in_rdy_4             (in_rdy_4),
                          
    .in_data_5            (in_data_5),
    .in_ctrl_5            (in_ctrl_5),
    .in_wr_5              (in_wr_5),
    .in_rdy_5             (in_rdy_5),
                          
    .in_data_6            (in_data_6),
    .in_ctrl_6            (in_ctrl_6),
    .in_wr_6              (in_wr_6),
    .in_rdy_6             (in_rdy_6),
                          
    .in_data_7            (in_data_7),
    .in_ctrl_7            (in_ctrl_7),
    .in_wr_7              (in_wr_7),
    .in_rdy_7             (in_rdy_7),
                          
      // --- Register interface
    .reg_req_in           (in_arb_in_reg_req),
    .reg_ack_in           (in_arb_in_reg_ack),
    .reg_rd_wr_L_in       (in_arb_in_reg_rd_wr_L),
    .reg_addr_in          (in_arb_in_reg_addr),
    .reg_data_in          (in_arb_in_reg_data),
    .reg_src_in           (in_arb_in_reg_src),

    .reg_req_out          (op_lut_in_reg_req),
    .reg_ack_out          (op_lut_in_reg_ack),
    .reg_rd_wr_L_out      (op_lut_in_reg_rd_wr_L),
    .reg_addr_out         (op_lut_in_reg_addr),
    .reg_data_out         (op_lut_in_reg_data),
    .reg_src_out          (op_lut_in_reg_src),
                          
      // --- Misc
    .reset                (reset),
    .clk                  (clk)
    );

   output_port_lookup
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .INPUT_ARBITER_STAGE_NUM(IN_ARB_STAGE_NUM),
       .STAGE_NUM(OP_LUT_STAGE_NUM),
       .NUM_OUTPUT_QUEUES(NUM_OUTPUT_QUEUES),
       .NUM_IQ_BITS(NUM_IQ_BITS))
   output_port_lookup
     (
     /*
     .out_data            (oq_in_data),
     .out_ctrl             (oq_in_ctrl),
     .out_wr               (oq_in_wr),
     .out_rdy              (oq_in_rdy),
     */
                           
      // --- Interface to the rx input queues
     .in_data              (op_lut_in_data),
     .in_ctrl              (op_lut_in_ctrl),
     .in_wr                (op_lut_in_wr),
     .in_rdy               (op_lut_in_rdy),
                           
      // --- Register interface
     .reg_req_in           (op_lut_in_reg_req),
     .reg_ack_in           (op_lut_in_reg_ack),
     .reg_rd_wr_L_in       (op_lut_in_reg_rd_wr_L),
     .reg_addr_in          (op_lut_in_reg_addr),
     .reg_data_in          (op_lut_in_reg_data),
     .reg_src_in           (op_lut_in_reg_src),

     .reg_req_out          (oq_in_reg_req),
     .reg_ack_out          (oq_in_reg_ack),
     .reg_rd_wr_L_out      (oq_in_reg_rd_wr_L),
     .reg_addr_out         (oq_in_reg_addr),
     .reg_data_out         (oq_in_reg_data),
     .reg_src_out          (oq_in_reg_src),
	
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

     .start_update	   (start_update),
     .flush_ddr	   (flush_ddr),
     .start_load	   (start_load),
     .compute_system_reset	(compute_system_reset),
	//write interface to DDR (used by load data function)
        .dram_fifo_writedata    (dram_fifo_writedata),
        .dram_fifo_write        (dram_fifo_write),
        .dram_fifo_full         (dram_fifo_full),

     .check_terminate (check_terminate),
     .num_keys (num_keys),
     .log_2_num_workers (log_2_num_workers),
     .shard_id (shard_id),
     .max_n_values (max_n_values),
     .filter_threshold (filter_threshold),
     .interpkt_gap_cycles(interpkt_gap_cycles),

     .max_fpga_procs (max_fpga_procs),
.proc_bit_mask(proc_bit_mask),
     .algo_selection (algo_selection),

      // --- Misc
     .clk                  (clk),
     .reset                (reset));


  packet_composer #(
		.WORKER_ADDR_WIDTH(WORKER_ADDR_WIDTH),
		.TOTAL_DATA(TOTAL_DATA)
	) composer (
		
   	// --- interface to next module
   	.out_wr		(oq_in_wr),
   	.out_data	(oq_in_data),
   	.out_ctrl	(oq_in_ctrl),     // new checksum assuming decremented TTL
   	.out_rdy	(oq_in_rdy),
	//.out_rdy 	(), //Deepak - TEST ONLY

        .iteration_accum_value (iteration_accum_value),
        .iteration_terminate_check (check_terminate),

	//read interface from DDR (used by flush data function)
        .dram_fifo_readdata     (dram_fifo_readdata),
        .dram_fifo_read         (dram_fifo_read),
        .dram_fifo_empty        (dram_fifo_empty),
	.num_keys		(num_keys),

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


	.interpkt_gap_cycles		(interpkt_gap_cycles),
	.shard_id (shard_id),
	.log_2_num_workers_in (log_2_num_workers),
	.start_update (start_update),
   	// misc
	.reset		((reset|compute_system_reset)),//pkt composer although instantiated here must be reset along with compute system
   	.clk		(clk)
   );

   output_queues
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .OP_LUT_STAGE_NUM(OP_LUT_STAGE_NUM),
       .NUM_OUTPUT_QUEUES(NUM_OUTPUT_QUEUES),
       .STAGE_NUM(OQ_STAGE_NUM),
       .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH))
   output_queues
     (// --- data path interface
    .out_data_0       (out_data_0),
    .out_ctrl_0       (out_ctrl_0),
    .out_wr_0         (out_wr_0),
    .out_rdy_0        (out_rdy_0),
                      
    .out_data_1       (out_data_1),
    .out_ctrl_1       (out_ctrl_1),
    .out_wr_1         (out_wr_1),
    .out_rdy_1        (out_rdy_1),
                      
    .out_data_2       (out_data_2),
    .out_ctrl_2       (out_ctrl_2),
    .out_wr_2         (out_wr_2),
    .out_rdy_2        (out_rdy_2),
                      
    .out_data_3       (out_data_3),
    .out_ctrl_3       (out_ctrl_3),
    .out_wr_3         (out_wr_3),
    .out_rdy_3        (out_rdy_3),
                      
    .out_data_4       (out_data_4),
    .out_ctrl_4       (out_ctrl_4),
    .out_wr_4         (out_wr_4),
    .out_rdy_4        (out_rdy_4),
                      
    .out_data_5       (out_data_5),
    .out_ctrl_5       (out_ctrl_5),
    .out_wr_5         (out_wr_5),
    .out_rdy_5        (out_rdy_5),
                      
    .out_data_6       (out_data_6),
    .out_ctrl_6       (out_ctrl_6),
    .out_wr_6         (out_wr_6),
    .out_rdy_6        (out_rdy_6),
                      
    .out_data_7       (out_data_7),
    .out_ctrl_7       (out_ctrl_7),
    .out_wr_7         (out_wr_7),
    .out_rdy_7        (out_rdy_7),
                      
      // --- Interface to the previous module
    .in_data          (oq_in_data),
    .in_ctrl          (oq_in_ctrl),
    .in_rdy           (oq_in_rdy),
    .in_wr            (oq_in_wr),
                      
      // --- Register interface
    .reg_req_in       (oq_in_reg_req),
    .reg_ack_in       (oq_in_reg_ack),
    .reg_rd_wr_L_in   (oq_in_reg_rd_wr_L),
    .reg_addr_in      (oq_in_reg_addr),
    .reg_data_in      (oq_in_reg_data),
    .reg_src_in       (oq_in_reg_src),

    .reg_req_out      (udp_reg_req_in),
    .reg_ack_out      (udp_reg_ack_in),
    .reg_rd_wr_L_out  (udp_reg_rd_wr_L_in),
    .reg_addr_out     (udp_reg_addr_in),
    .reg_data_out     (udp_reg_data_in),
    .reg_src_out      (udp_reg_src_in),

      // --- SRAM sm interface
    .wr_0_addr        (wr_0_addr),
    .wr_0_req         (wr_0_req),
    .wr_0_ack         (wr_0_ack),
    .wr_0_data        (wr_0_data),
    .rd_0_ack         (rd_0_ack),
    .rd_0_data        (rd_0_data),
    .rd_0_vld         (rd_0_vld),
    .rd_0_addr        (rd_0_addr),
    .rd_0_req         (rd_0_req),
                      
                      
      // --- Misc
    .clk              (clk),
    .reset            (reset));


   //--------------------------------------------------
   //
   // --- User data path register master
   //
   //     Takes the register accesses from core,
   //     sends them around the User Data Path module
   //     ring and then returns the replies back
   //     to the core
   //
   //--------------------------------------------------

   udp_reg_master #(
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) udp_reg_master (
      // Core register interface signals
      .core_reg_req                          (reg_req),
      .core_reg_ack                          (reg_ack),
      .core_reg_rd_wr_L                      (reg_rd_wr_L),

      .core_reg_addr                         (reg_addr),

      .core_reg_rd_data                      (reg_rd_data),
      .core_reg_wr_data                      (reg_wr_data),

      // UDP register interface signals (output)
      .reg_req_out                           (in_arb_in_reg_req),
      .reg_ack_out                           (in_arb_in_reg_ack),
      .reg_rd_wr_L_out                       (in_arb_in_reg_rd_wr_L),

      .reg_addr_out                          (in_arb_in_reg_addr),
      .reg_data_out                          (in_arb_in_reg_data),

      .reg_src_out                           (in_arb_in_reg_src),

      // UDP register interface signals (input)
      .reg_req_in                            (udp_reg_req_in),
      .reg_ack_in                            (udp_reg_ack_in),
      .reg_rd_wr_L_in                        (udp_reg_rd_wr_L_in),

      .reg_addr_in                           (udp_reg_addr_in),
      .reg_data_in                           (udp_reg_data_in),

      .reg_src_in                            (udp_reg_src_in),

      //
      .clk                                   (clk),
      .reset                                 (reset)
   );


endmodule // user_data_path

