
module compute_system #(
	parameter DATA_WIDTH=32,
	parameter MAX_NUM_PROCS=8,
	parameter MAX_NUM_EXT_PROCS=0, //number of processors used for processing external updates
	parameter PROCS_ON_SNOOPY_BUS=MAX_NUM_PROCS+MAX_NUM_EXT_PROCS, //total processors sharing snoopy bus
	parameter WORKER_ADDR_WIDTH=1,
	parameter WORKER_FIFO_DEPTH=256,
	parameter ADDRESS_WIDTH=31,
	parameter DDR_BASE=31'h00000000,
   	parameter DDR_SIZE=1073741824, //1Gb

	parameter MAX_N_VALUES=1024,  
	parameter MAX_K_VALUES=128, 
	parameter TOTAL_KEYS=4,
   	parameter DEFAULT_READ_LENGTH=32,
	parameter SORT_WIDTH=1*DATA_WIDTH,
	parameter MAX_LOCK_KEYS=4,

	parameter MAX_WORDS_PER_PACKET = 150, //total data = 150*64 bits/8 bit = 1200bytes
	parameter TX_EXT_FIFO_DEPTH=2*MAX_WORDS_PER_PACKET, //how many 64 bit words ?
	parameter RX_EXT_FIFO_DEPTH=512,  //how many 64 bit words ?
	parameter MAX_NUM_WORKERS=4 //HOW MANY WORKERS IN CLUSTER ?
) (
input clk,
input reset,

//i/f b/w TX EXT FIFO and packet composer
output [63:0]       tx_ext_update_0_q,
input               tx_ext_update_0_rdreq,
output              tx_ext_update_0_empty,
output 		    tx_ext_update_0_almost_full,

output [63:0]       tx_ext_update_1_q,
input               tx_ext_update_1_rdreq,
output              tx_ext_update_1_empty,
output 		    tx_ext_update_1_almost_full,

output [63:0]       tx_ext_update_2_q,
input               tx_ext_update_2_rdreq,
output              tx_ext_update_2_empty,
output 		    tx_ext_update_2_almost_full,

output [63:0]       tx_ext_update_3_q,
input               tx_ext_update_3_rdreq,
output              tx_ext_update_3_empty,
output 		    tx_ext_update_3_almost_full,

//i/f b/w op_lut_process_sm.v and RX EXT FIFO
input [63:0]       rx_ext_update_data,

output             rx_ext_update_0_full,
input              rx_ext_update_0_wrreq,
output             rx_ext_update_1_full,
input              rx_ext_update_1_wrreq,
output             rx_ext_update_2_full,
input              rx_ext_update_2_wrreq,
output             rx_ext_update_3_full,
input              rx_ext_update_3_wrreq,
output             rx_ext_update_4_full,
input              rx_ext_update_4_wrreq,
output             rx_ext_update_5_full,
input              rx_ext_update_5_wrreq,
output             rx_ext_update_6_full,
input              rx_ext_update_6_wrreq,
output             rx_ext_update_7_full,
input              rx_ext_update_7_wrreq,

input [7:0]	   proc_bit_mask,

input start_update,
input compute_system_reset,

//compute system memory interface
output 				topk_control_fixed_location,
output [ADDRESS_WIDTH-1:0] 	topk_control_read_base,
output [ADDRESS_WIDTH-1:0] 	topk_control_read_length,
output  			topk_control_go,
input 				topk_control_done,

// user logic inputs and outputs
output wire 				 topk_user_read_buffer,
input [255:0] 				 topk_user_buffer_output_data,
input 					 topk_user_data_available,

output [31:0]  iteration_accum_value,
input [31:0]   num_keys_in,
output [31:0]  num_keys_out,
input [31:0]   log_2_num_workers_in,
output [31:0]  log_2_num_workers_out,   
input [31:0]   shard_id,
input [31:0]   max_n_values,
input [31:0]   filter_threshold,
input [3:0]    max_fpga_procs,
input	       algo_selection,

output wire [30:0]  accumulator_wr_0_avalon_master_address,       // accumulator_wr_0_avalon_master.address
output wire         accumulator_wr_0_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_0_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_0_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_0_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_0_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_0_avalon_master_address,       // accumulator_rd_0_avalon_master.address
output wire         accumulator_rd_0_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_0_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_0_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_0_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_0_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_0_avalon_master_waitrequest,   //

output wire [30:0]  link_rd_0_avalon_master_address,       // link_rd_0_avalon_master.address
output wire         link_rd_0_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_0_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_0_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_0_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_0_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_0_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_1_avalon_master_address,       // accumulator_wr_1_avalon_master.address
output wire         accumulator_wr_1_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_1_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_1_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_1_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_1_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_1_avalon_master_address,       // accumulator_rd_1_avalon_master.address
output wire         accumulator_rd_1_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_1_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_1_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_1_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_1_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_1_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_1_avalon_master_address,       // link_rd_1_avalon_master.address
output wire         link_rd_1_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_1_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_1_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_1_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_1_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_1_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_2_avalon_master_address,       // accumulator_wr_2_avalon_master.address
output wire         accumulator_wr_2_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_2_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_2_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_2_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_2_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_2_avalon_master_address,       // accumulator_rd_2_avalon_master.address
output wire         accumulator_rd_2_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_2_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_2_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_2_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_2_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_2_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_2_avalon_master_address,       // link_rd_2_avalon_master.address
output wire         link_rd_2_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_2_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_2_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_2_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_2_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_2_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_3_avalon_master_address,       // accumulator_wr_3_avalon_master.address
output wire         accumulator_wr_3_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_3_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_3_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_3_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_3_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_3_avalon_master_address,       // accumulator_rd_3_avalon_master.address
output wire         accumulator_rd_3_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_3_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_3_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_3_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_3_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_3_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_3_avalon_master_address,       // link_rd_3_avalon_master.address
output wire         link_rd_3_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_3_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_3_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_3_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_3_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_3_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_4_avalon_master_address,       // accumulator_wr_4_avalon_master.address
output wire         accumulator_wr_4_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_4_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_4_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_4_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_4_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_4_avalon_master_address,       // accumulator_rd_4_avalon_master.address
output wire         accumulator_rd_4_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_4_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_4_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_4_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_4_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_4_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_4_avalon_master_address,       // link_rd_4_avalon_master.address
output wire         link_rd_4_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_4_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_4_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_4_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_4_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_4_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_5_avalon_master_address,       // accumulator_wr_5_avalon_master.address
output wire         accumulator_wr_5_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_5_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_5_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_5_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_5_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_5_avalon_master_address,       // accumulator_rd_5_avalon_master.address
output wire         accumulator_rd_5_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_5_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_5_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_5_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_5_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_5_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_5_avalon_master_address,       // link_rd_5_avalon_master.address
output wire         link_rd_5_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_5_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_5_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_5_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_5_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_5_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_6_avalon_master_address,       // accumulator_wr_6_avalon_master.address
output wire         accumulator_wr_6_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_6_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_6_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_6_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_6_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_6_avalon_master_address,       // accumulator_rd_6_avalon_master.address
output wire         accumulator_rd_6_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_6_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_6_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_6_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_6_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_6_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_6_avalon_master_address,       // link_rd_6_avalon_master.address
output wire         link_rd_6_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_6_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_6_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_6_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_6_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_6_avalon_master_waitrequest,   //

output wire [30:0]  accumulator_wr_7_avalon_master_address,       // accumulator_wr_7_avalon_master.address
output wire         accumulator_wr_7_avalon_master_write,         //                               .write
output wire [31:0]  accumulator_wr_7_avalon_master_byteenable,    //                               .byteenable
output wire [255:0] accumulator_wr_7_avalon_master_writedata,     //                               .writedata
output wire [2:0]   accumulator_wr_7_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_wr_7_avalon_master_waitrequest,   //                               .waitrequest

output wire [30:0]  accumulator_rd_7_avalon_master_address,       // accumulator_rd_7_avalon_master.address
output wire         accumulator_rd_7_avalon_master_read,          //                               .read
output wire [31:0]  accumulator_rd_7_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] accumulator_rd_7_avalon_master_readdata,      //                               .readdata
input  wire         accumulator_rd_7_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   accumulator_rd_7_avalon_master_burstcount,    //                               .burstcount
input  wire         accumulator_rd_7_avalon_master_waitrequest,   //   

output wire [30:0]  link_rd_7_avalon_master_address,       // link_rd_7_avalon_master.address
output wire         link_rd_7_avalon_master_read,          //                               .read
output wire [31:0]  link_rd_7_avalon_master_byteenable,    //                               .byteenable
input  wire [255:0] link_rd_7_avalon_master_readdata,      //                               .readdata
input  wire         link_rd_7_avalon_master_readdatavalid, //                               .readdatavalid
output wire [2:0]   link_rd_7_avalon_master_burstcount,    //                               .burstcount
input  wire         link_rd_7_avalon_master_waitrequest   //


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

/*Parameters*/

localparam FIFO_DATA_WIDTH = DATA_WIDTH*2;
//localparam LOCAL_MEMORY_ADD_WIDTH=log2(LOCAL_MEMORY_DEPTH);
//localparam MUX_ADDR_WIDTH=log2(MAX_NUM_PROCS);



// netfpga out 
wire  [63:0]   netfpga_out_data; //hard code for sopc
wire           netfpga_out_wr;
wire           netfpga_out_rdy;

wire internal_system_reset;

/***************Wires********************/
//PE fifo inputs
wire [FIFO_DATA_WIDTH-1:0] fifo_datain[MAX_NUM_PROCS-1:0];
wire [MAX_NUM_PROCS-1:0] fifo_rdempty;
wire [MAX_NUM_PROCS-1:0] fifo_rdreq;
wire [FIFO_DATA_WIDTH*MAX_NUM_PROCS-1:0] fifo_datain_internal;

wire [FIFO_DATA_WIDTH-1:0]    accumulator_local_writedata[MAX_NUM_PROCS-1:0];
wire [MAX_NUM_PROCS-1:0]        accumulator_local_wrreq;
wire [MAX_NUM_PROCS-1:0]        accumulator_local_full;
wire [MAX_NUM_PROCS-1:0]        accumulator_local_empty;

wire [30:0]  accumulator_wr_avalon_master_address[MAX_NUM_PROCS-1:0];       
wire         accumulator_wr_avalon_master_write[MAX_NUM_PROCS-1:0];         
wire [31:0]  accumulator_wr_avalon_master_byteenable[MAX_NUM_PROCS-1:0];    
wire [255:0] accumulator_wr_avalon_master_writedata[MAX_NUM_PROCS-1:0];     
wire [2:0]   accumulator_wr_avalon_master_burstcount[MAX_NUM_PROCS-1:0];    
wire         accumulator_wr_avalon_master_waitrequest[MAX_NUM_PROCS-1:0];  

wire [30:0]  accumulator_rd_avalon_master_address[MAX_NUM_PROCS-1:0];       
wire         accumulator_rd_avalon_master_read[MAX_NUM_PROCS-1:0];          
wire [31:0]  accumulator_rd_avalon_master_byteenable[MAX_NUM_PROCS-1:0];    
wire [255:0] accumulator_rd_avalon_master_readdata[MAX_NUM_PROCS-1:0];     
wire         accumulator_rd_avalon_master_readdatavalid[MAX_NUM_PROCS-1:0]; 
wire [2:0]   accumulator_rd_avalon_master_burstcount[MAX_NUM_PROCS-1:0];    
wire         accumulator_rd_avalon_master_waitrequest[MAX_NUM_PROCS-1:0];  

wire [30:0]  link_rd_avalon_master_address[MAX_NUM_PROCS-1:0];       
wire         link_rd_avalon_master_read[MAX_NUM_PROCS-1:0];          
wire [31:0]  link_rd_avalon_master_byteenable[MAX_NUM_PROCS-1:0];    
wire [255:0] link_rd_avalon_master_readdata[MAX_NUM_PROCS-1:0];     
wire         link_rd_avalon_master_readdatavalid[MAX_NUM_PROCS-1:0]; 
wire [2:0]   link_rd_avalon_master_burstcount[MAX_NUM_PROCS-1:0];    
wire         link_rd_avalon_master_waitrequest[MAX_NUM_PROCS-1:0];  

	
wire         wr_user_write_buffer[MAX_NUM_PROCS-1:0];          
wire [255:0] wr_user_buffer_data[MAX_NUM_PROCS-1:0];      
wire         wr_user_buffer_full[MAX_NUM_PROCS-1:0];        

wire         wr_control_fixed_location[MAX_NUM_PROCS-1:0]; 
wire [30:0]  wr_control_write_base[MAX_NUM_PROCS-1:0];     
wire [30:0]  wr_control_write_length[MAX_NUM_PROCS-1:0];   
wire         wr_control_go[MAX_NUM_PROCS-1:0];             
wire         wr_control_done[MAX_NUM_PROCS-1:0];            

wire         user_read_buffer[MAX_NUM_PROCS-1:0];       
wire [255:0] user_buffer_data[MAX_NUM_PROCS-1:0];     
wire         user_data_available[MAX_NUM_PROCS-1:0];   
	
wire         control_fixed_location[MAX_NUM_PROCS-1:0]; 
wire [30:0]  control_read_base[MAX_NUM_PROCS-1:0];      
wire [30:0]  control_read_length[MAX_NUM_PROCS-1:0];    
wire         control_go[MAX_NUM_PROCS-1:0];             
wire         control_done[MAX_NUM_PROCS-1:0];            
wire         control_early_done[MAX_NUM_PROCS-1:0];     

wire         link_user_read_buffer[MAX_NUM_PROCS-1:0];       
wire [255:0] link_user_buffer_data[MAX_NUM_PROCS-1:0];     
wire         link_user_data_available[MAX_NUM_PROCS-1:0];   
	
wire         link_control_fixed_location[MAX_NUM_PROCS-1:0]; 
wire [30:0]  link_control_read_base[MAX_NUM_PROCS-1:0];      
wire [30:0]  link_control_read_length[MAX_NUM_PROCS-1:0];    
wire         link_control_go[MAX_NUM_PROCS-1:0];             
wire         link_control_done[MAX_NUM_PROCS-1:0];            
wire         link_control_early_done[MAX_NUM_PROCS-1:0];     


/***Logic***/
assign num_keys_out = num_keys_in;
assign log_2_num_workers_out = log_2_num_workers_in;

assign accumulator_wr_0_avalon_master_address = accumulator_wr_avalon_master_address[0];
assign accumulator_wr_0_avalon_master_write = accumulator_wr_avalon_master_write[0];
assign accumulator_wr_0_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[0];
assign accumulator_wr_0_avalon_master_write = accumulator_wr_avalon_master_write[0];
assign accumulator_wr_0_avalon_master_writedata = accumulator_wr_avalon_master_writedata[0];
assign accumulator_wr_0_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[0];
assign accumulator_wr_avalon_master_waitrequest[0] = accumulator_wr_0_avalon_master_waitrequest;

assign accumulator_rd_0_avalon_master_address = accumulator_rd_avalon_master_address[0];
assign accumulator_rd_0_avalon_master_read = accumulator_rd_avalon_master_read[0];
assign accumulator_rd_0_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[0];
assign accumulator_rd_avalon_master_readdata[0] = accumulator_rd_0_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[0] = accumulator_rd_0_avalon_master_readdatavalid;
assign accumulator_rd_0_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[0];
assign accumulator_rd_avalon_master_waitrequest[0] = accumulator_rd_0_avalon_master_waitrequest;

assign link_rd_0_avalon_master_address = link_rd_avalon_master_address[0];
assign link_rd_0_avalon_master_read = link_rd_avalon_master_read[0];
assign link_rd_0_avalon_master_byteenable = link_rd_avalon_master_byteenable[0];
assign link_rd_avalon_master_readdata[0] = link_rd_0_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[0] = link_rd_0_avalon_master_readdatavalid;
assign link_rd_0_avalon_master_burstcount = link_rd_avalon_master_burstcount[0];
assign link_rd_avalon_master_waitrequest[0] = link_rd_0_avalon_master_waitrequest;

assign accumulator_wr_1_avalon_master_address = accumulator_wr_avalon_master_address[1];
assign accumulator_wr_1_avalon_master_write = accumulator_wr_avalon_master_write[1];
assign accumulator_wr_1_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[1];
assign accumulator_wr_1_avalon_master_write = accumulator_wr_avalon_master_write[1];
assign accumulator_wr_1_avalon_master_writedata = accumulator_wr_avalon_master_writedata[1];
assign accumulator_wr_1_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[1];
assign accumulator_wr_avalon_master_waitrequest[1] = accumulator_wr_1_avalon_master_waitrequest;

assign accumulator_rd_1_avalon_master_address = accumulator_rd_avalon_master_address[1];
assign accumulator_rd_1_avalon_master_read = accumulator_rd_avalon_master_read[1];
assign accumulator_rd_1_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[1];
assign accumulator_rd_avalon_master_readdata[1] = accumulator_rd_1_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[1] = accumulator_rd_1_avalon_master_readdatavalid;
assign accumulator_rd_1_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[1];
assign accumulator_rd_avalon_master_waitrequest[1] = accumulator_rd_1_avalon_master_waitrequest;

assign link_rd_1_avalon_master_address = link_rd_avalon_master_address[1];
assign link_rd_1_avalon_master_read = link_rd_avalon_master_read[1];
assign link_rd_1_avalon_master_byteenable = link_rd_avalon_master_byteenable[1];
assign link_rd_avalon_master_readdata[1] = link_rd_1_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[1] = link_rd_1_avalon_master_readdatavalid;
assign link_rd_1_avalon_master_burstcount = link_rd_avalon_master_burstcount[1];
assign link_rd_avalon_master_waitrequest[1] = link_rd_1_avalon_master_waitrequest;


assign accumulator_wr_2_avalon_master_address = accumulator_wr_avalon_master_address[2];
assign accumulator_wr_2_avalon_master_write = accumulator_wr_avalon_master_write[2];
assign accumulator_wr_2_avalon_master_writedata = accumulator_wr_avalon_master_writedata[2];
assign accumulator_wr_2_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[2];
assign accumulator_wr_2_avalon_master_write = accumulator_wr_avalon_master_write[2];
assign accumulator_wr_2_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[2];
assign accumulator_wr_avalon_master_waitrequest[2] = accumulator_wr_2_avalon_master_waitrequest;

assign accumulator_rd_2_avalon_master_address = accumulator_rd_avalon_master_address[2];
assign accumulator_rd_2_avalon_master_read = accumulator_rd_avalon_master_read[2];
assign accumulator_rd_2_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[2];
assign accumulator_rd_avalon_master_readdata[2] = accumulator_rd_2_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[2] = accumulator_rd_2_avalon_master_readdatavalid;
assign accumulator_rd_2_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[2];
assign accumulator_rd_avalon_master_waitrequest[2] = accumulator_rd_2_avalon_master_waitrequest;

assign link_rd_2_avalon_master_address = link_rd_avalon_master_address[2];
assign link_rd_2_avalon_master_read = link_rd_avalon_master_read[2];
assign link_rd_2_avalon_master_byteenable = link_rd_avalon_master_byteenable[2];
assign link_rd_avalon_master_readdata[2] = link_rd_2_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[2] = link_rd_2_avalon_master_readdatavalid;
assign link_rd_2_avalon_master_burstcount = link_rd_avalon_master_burstcount[2];
assign link_rd_avalon_master_waitrequest[2] = link_rd_2_avalon_master_waitrequest;

assign accumulator_wr_3_avalon_master_address = accumulator_wr_avalon_master_address[3];
assign accumulator_wr_3_avalon_master_write = accumulator_wr_avalon_master_write[3];
assign accumulator_wr_3_avalon_master_writedata = accumulator_wr_avalon_master_writedata[3];
assign accumulator_wr_3_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[3];
assign accumulator_wr_3_avalon_master_write = accumulator_wr_avalon_master_write[3];
assign accumulator_wr_3_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[3];
assign accumulator_wr_avalon_master_waitrequest[3] = accumulator_wr_3_avalon_master_waitrequest;

assign accumulator_rd_3_avalon_master_address = accumulator_rd_avalon_master_address[3];
assign accumulator_rd_3_avalon_master_read = accumulator_rd_avalon_master_read[3];
assign accumulator_rd_3_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[3];
assign accumulator_rd_avalon_master_readdata[3] = accumulator_rd_3_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[3] = accumulator_rd_3_avalon_master_readdatavalid;
assign accumulator_rd_3_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[3];
assign accumulator_rd_avalon_master_waitrequest[3] = accumulator_rd_3_avalon_master_waitrequest;

assign link_rd_3_avalon_master_address = link_rd_avalon_master_address[3];
assign link_rd_3_avalon_master_read = link_rd_avalon_master_read[3];
assign link_rd_3_avalon_master_byteenable = link_rd_avalon_master_byteenable[3];
assign link_rd_avalon_master_readdata[3] = link_rd_3_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[3] = link_rd_3_avalon_master_readdatavalid;
assign link_rd_3_avalon_master_burstcount = link_rd_avalon_master_burstcount[3];
assign link_rd_avalon_master_waitrequest[3] = link_rd_3_avalon_master_waitrequest;

assign accumulator_wr_4_avalon_master_address = accumulator_wr_avalon_master_address[4];
assign accumulator_wr_4_avalon_master_write = accumulator_wr_avalon_master_write[4];
assign accumulator_wr_4_avalon_master_writedata = accumulator_wr_avalon_master_writedata[4];
assign accumulator_wr_4_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[4];
assign accumulator_wr_4_avalon_master_write = accumulator_wr_avalon_master_write[4];
assign accumulator_wr_4_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[4];
assign accumulator_wr_avalon_master_waitrequest[4] = accumulator_wr_4_avalon_master_waitrequest;

assign accumulator_rd_4_avalon_master_address = accumulator_rd_avalon_master_address[4];
assign accumulator_rd_4_avalon_master_read = accumulator_rd_avalon_master_read[4];
assign accumulator_rd_4_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[4];
assign accumulator_rd_avalon_master_readdata[4] = accumulator_rd_4_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[4] = accumulator_rd_4_avalon_master_readdatavalid;
assign accumulator_rd_4_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[4];
assign accumulator_rd_avalon_master_waitrequest[4] = accumulator_rd_4_avalon_master_waitrequest;

assign link_rd_4_avalon_master_address = link_rd_avalon_master_address[4];
assign link_rd_4_avalon_master_read = link_rd_avalon_master_read[4];
assign link_rd_4_avalon_master_byteenable = link_rd_avalon_master_byteenable[4];
assign link_rd_avalon_master_readdata[4] = link_rd_4_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[4] = link_rd_4_avalon_master_readdatavalid;
assign link_rd_4_avalon_master_burstcount = link_rd_avalon_master_burstcount[4];
assign link_rd_avalon_master_waitrequest[4] = link_rd_4_avalon_master_waitrequest;

assign accumulator_wr_5_avalon_master_address = accumulator_wr_avalon_master_address[5];
assign accumulator_wr_5_avalon_master_write = accumulator_wr_avalon_master_write[5];
assign accumulator_wr_5_avalon_master_writedata = accumulator_wr_avalon_master_writedata[5];
assign accumulator_wr_5_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[5];
assign accumulator_wr_5_avalon_master_write = accumulator_wr_avalon_master_write[5];
assign accumulator_wr_5_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[5];
assign accumulator_wr_avalon_master_waitrequest[5] = accumulator_wr_5_avalon_master_waitrequest;

assign accumulator_rd_5_avalon_master_address = accumulator_rd_avalon_master_address[5];
assign accumulator_rd_5_avalon_master_read = accumulator_rd_avalon_master_read[5];
assign accumulator_rd_5_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[5];
assign accumulator_rd_avalon_master_readdata[5] = accumulator_rd_5_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[5] = accumulator_rd_5_avalon_master_readdatavalid;
assign accumulator_rd_5_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[5];
assign accumulator_rd_avalon_master_waitrequest[5] = accumulator_rd_5_avalon_master_waitrequest;

assign link_rd_5_avalon_master_address = link_rd_avalon_master_address[5];
assign link_rd_5_avalon_master_read = link_rd_avalon_master_read[5];
assign link_rd_5_avalon_master_byteenable = link_rd_avalon_master_byteenable[5];
assign link_rd_avalon_master_readdata[5] = link_rd_5_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[5] = link_rd_5_avalon_master_readdatavalid;
assign link_rd_5_avalon_master_burstcount = link_rd_avalon_master_burstcount[5];
assign link_rd_avalon_master_waitrequest[5] = link_rd_5_avalon_master_waitrequest;

assign accumulator_wr_6_avalon_master_address = accumulator_wr_avalon_master_address[6];
assign accumulator_wr_6_avalon_master_write = accumulator_wr_avalon_master_write[6];
assign accumulator_wr_6_avalon_master_writedata = accumulator_wr_avalon_master_writedata[6];
assign accumulator_wr_6_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[6];
assign accumulator_wr_6_avalon_master_write = accumulator_wr_avalon_master_write[6];
assign accumulator_wr_6_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[6];
assign accumulator_wr_avalon_master_waitrequest[6] = accumulator_wr_6_avalon_master_waitrequest;

assign accumulator_rd_6_avalon_master_address = accumulator_rd_avalon_master_address[6];
assign accumulator_rd_6_avalon_master_read = accumulator_rd_avalon_master_read[6];
assign accumulator_rd_6_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[6];
assign accumulator_rd_avalon_master_readdata[6] = accumulator_rd_6_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[6] = accumulator_rd_6_avalon_master_readdatavalid;
assign accumulator_rd_6_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[6];
assign accumulator_rd_avalon_master_waitrequest[6] = accumulator_rd_6_avalon_master_waitrequest;

assign link_rd_6_avalon_master_address = link_rd_avalon_master_address[6];
assign link_rd_6_avalon_master_read = link_rd_avalon_master_read[6];
assign link_rd_6_avalon_master_byteenable = link_rd_avalon_master_byteenable[6];
assign link_rd_avalon_master_readdata[6] = link_rd_6_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[6] = link_rd_6_avalon_master_readdatavalid;
assign link_rd_6_avalon_master_burstcount = link_rd_avalon_master_burstcount[6];
assign link_rd_avalon_master_waitrequest[6] = link_rd_6_avalon_master_waitrequest;

assign accumulator_wr_7_avalon_master_address = accumulator_wr_avalon_master_address[7];
assign accumulator_wr_7_avalon_master_write = accumulator_wr_avalon_master_write[7];
assign accumulator_wr_7_avalon_master_writedata = accumulator_wr_avalon_master_writedata[7];
assign accumulator_wr_7_avalon_master_byteenable = accumulator_wr_avalon_master_byteenable[7];
assign accumulator_wr_7_avalon_master_write = accumulator_wr_avalon_master_write[7];
assign accumulator_wr_7_avalon_master_burstcount = accumulator_wr_avalon_master_burstcount[7];
assign accumulator_wr_avalon_master_waitrequest[7] = accumulator_wr_7_avalon_master_waitrequest;

assign accumulator_rd_7_avalon_master_address = accumulator_rd_avalon_master_address[7];
assign accumulator_rd_7_avalon_master_read = accumulator_rd_avalon_master_read[7];
assign accumulator_rd_7_avalon_master_byteenable = accumulator_rd_avalon_master_byteenable[7];
assign accumulator_rd_avalon_master_readdata[7] = accumulator_rd_7_avalon_master_readdata;
assign accumulator_rd_avalon_master_readdatavalid[7] = accumulator_rd_7_avalon_master_readdatavalid;
assign accumulator_rd_7_avalon_master_burstcount = accumulator_rd_avalon_master_burstcount[7];
assign accumulator_rd_avalon_master_waitrequest[7] = accumulator_rd_7_avalon_master_waitrequest;

assign link_rd_7_avalon_master_address = link_rd_avalon_master_address[7];
assign link_rd_7_avalon_master_read = link_rd_avalon_master_read[7];
assign link_rd_7_avalon_master_byteenable = link_rd_avalon_master_byteenable[7];
assign link_rd_avalon_master_readdata[7] = link_rd_7_avalon_master_readdata;
assign link_rd_avalon_master_readdatavalid[7] = link_rd_7_avalon_master_readdatavalid;
assign link_rd_7_avalon_master_burstcount = link_rd_avalon_master_burstcount[7];
assign link_rd_avalon_master_waitrequest[7] = link_rd_7_avalon_master_waitrequest;


wire [63:0]     		tx_ext_update_data;
wire [MAX_NUM_WORKERS-1:0]      tx_ext_update_wrreq;
wire [MAX_NUM_WORKERS-1:0]      tx_ext_update_full;
wire [MAX_NUM_WORKERS-1:0]      tx_ext_update_almost_full;
wire [63:0]     		tx_ext_update_q[MAX_NUM_WORKERS-1:0];
wire [MAX_NUM_WORKERS-1:0]      tx_ext_update_rdreq;
wire [MAX_NUM_WORKERS-1:0]      tx_ext_update_empty;



wire 			        rx_ext_update_wrreq[MAX_NUM_PROCS-1:0];
wire 			        rx_ext_update_full[MAX_NUM_PROCS-1:0];
wire 			        rx_ext_update_almost_full[MAX_NUM_PROCS-1:0];
wire [63:0]     		rx_ext_update_q[MAX_NUM_PROCS-1:0];
wire 			        rx_ext_update_rdreq[MAX_NUM_PROCS-1:0];
wire 			        rx_ext_update_empty[MAX_NUM_PROCS-1:0];

assign tx_ext_update_0_q 		= tx_ext_update_q[0];
assign tx_ext_update_rdreq[0] 		= tx_ext_update_0_rdreq;
assign tx_ext_update_0_empty		= tx_ext_update_empty[0];
assign tx_ext_update_0_almost_full	= tx_ext_update_almost_full[0];

assign tx_ext_update_1_q 		= tx_ext_update_q[1];
assign tx_ext_update_rdreq[1] 		= tx_ext_update_1_rdreq;
assign tx_ext_update_1_empty		= tx_ext_update_empty[1];
assign tx_ext_update_1_almost_full	= tx_ext_update_almost_full[1];

assign tx_ext_update_2_q 		= tx_ext_update_q[2];
assign tx_ext_update_rdreq[2] 		= tx_ext_update_2_rdreq;
assign tx_ext_update_2_empty		= tx_ext_update_empty[2];
assign tx_ext_update_2_almost_full	= tx_ext_update_almost_full[2];

assign tx_ext_update_3_q 		= tx_ext_update_q[3];
assign tx_ext_update_rdreq[3] 		= tx_ext_update_3_rdreq;
assign tx_ext_update_3_empty		= tx_ext_update_empty[3];
assign tx_ext_update_3_almost_full	= tx_ext_update_almost_full[3];

assign rx_ext_update_wrreq[0] = rx_ext_update_0_wrreq;
assign rx_ext_update_0_full   = rx_ext_update_full[0];
assign rx_ext_update_wrreq[1] = rx_ext_update_1_wrreq;
assign rx_ext_update_1_full   = rx_ext_update_full[1];
assign rx_ext_update_wrreq[2] = rx_ext_update_2_wrreq;
assign rx_ext_update_2_full   = rx_ext_update_full[2];
assign rx_ext_update_wrreq[3] = rx_ext_update_3_wrreq;
assign rx_ext_update_3_full   = rx_ext_update_full[3];
assign rx_ext_update_wrreq[4] = rx_ext_update_4_wrreq;
assign rx_ext_update_4_full   = rx_ext_update_full[4];
assign rx_ext_update_wrreq[5] = rx_ext_update_5_wrreq;
assign rx_ext_update_5_full   = rx_ext_update_full[5];
assign rx_ext_update_wrreq[6] = rx_ext_update_6_wrreq;
assign rx_ext_update_6_full   = rx_ext_update_full[6];
assign rx_ext_update_wrreq[7] = rx_ext_update_7_wrreq;
assign rx_ext_update_7_full   = rx_ext_update_full[7];

/*

*/

wire [63:0] 	ext_fifo_data[MAX_NUM_PROCS-1:0];
wire  		ext_fifo_rdreq[MAX_NUM_PROCS-1:0];
wire  		ext_fifo_wrreq[MAX_NUM_PROCS-1:0];
wire [63:0]	ext_fifo_q[MAX_NUM_PROCS-1:0];
wire  		ext_fifo_empty[MAX_NUM_PROCS-1:0];
wire  		ext_fifo_full[MAX_NUM_PROCS-1:0];





genvar i;
generate
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin: xtfifo
txfifo #(
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .LOCAL_FIFO_DEPTH(64)
) ext_fifo (
        .clock          (clk),
	//.aclr           (reset),
	.aclr           (internal_system_reset),	
        .data	        (ext_fifo_data[i]),
        .rdreq          (ext_fifo_rdreq[i]),
        .wrreq          (ext_fifo_wrreq[i]),
        .q              (ext_fifo_q[i]),
        .empty          (ext_fifo_empty[i]),
        .full           (ext_fifo_full[i])
);

end
endgenerate

//Mux demux between compute unit fifos and worker fifos
fifo_arbiter #(
        .MAX_NUM_PROCS(MAX_NUM_PROCS),
        .DATA_WIDTH(DATA_WIDTH),              
	.WORKER_FIFO_DEPTH(WORKER_FIFO_DEPTH),
	.MAX_NUM_WORKERS(MAX_NUM_WORKERS)
   ) tx_fifo_arbiter (
	.clk	(clk),
	//.reset	(reset),
	.reset		(internal_system_reset),

	.ext_fifo_q	(ext_fifo_q),
	.ext_fifo_empty	(ext_fifo_empty),
	.ext_fifo_rdreq	(ext_fifo_rdreq),

	//Signals for external accumulation
	.tx_ext_update_data	(tx_ext_update_data),
	.tx_ext_update_wrreq	(tx_ext_update_wrreq),
	.tx_ext_update_full	(tx_ext_update_full),

	.max_fpga_procs		(max_fpga_procs),
	.log_2_num_workers_in	(log_2_num_workers_in)
);

//All updates that go outside of FPGA must be placed in the tx_ext_update_fifo (packet composer module reads this FIFO)
generate
for(i=0;i<MAX_NUM_WORKERS;i=i+1) begin: tx_ex_update_fifo
	txfifo_packet_composer #(
	     .DATA_WIDTH(64),
	     .LOCAL_FIFO_DEPTH(TX_EXT_FIFO_DEPTH)
	) tx_ext_update_fifo (
        	.clock          (clk),
	        //.aclr           (reset),
	        .aclr           (internal_system_reset),
	        .data           (tx_ext_update_data),
	        .rdreq          (tx_ext_update_rdreq[i]),
	        .wrreq          (tx_ext_update_wrreq[i]),
        	.q              (tx_ext_update_q[i]),
	        .empty          (tx_ext_update_empty[i]),
        	.full           (tx_ext_update_full[i]),
	        .usedw          (),
        	.almost_full    (tx_ext_update_almost_full[i])
	);
end
endgenerate

//All updates arriving in FPGA are collected into the rx_ext_update_fifo

generate
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin: rxfifo
txfifo #(
     .DATA_WIDTH(64),
     .LOCAL_FIFO_DEPTH(RX_EXT_FIFO_DEPTH)
) rx_ext_update_fifo (
       .clock          (clk),
       //.aclr           (reset),
       .aclr           (internal_system_reset),
       .data           (rx_ext_update_data),
       .rdreq          (rx_ext_update_rdreq[i]),
       .wrreq          (rx_ext_update_wrreq[i]),
       .q              (rx_ext_update_q[i]),
       .empty          (rx_ext_update_empty[i]),
       .full           (rx_ext_update_full[i]),
       .usedw          (),
       .almost_full    (rx_ext_update_almost_full[i])
); 
end
endgenerate
/*

//External updates will be distributed to EXT processors by RX_ARBITER module
rx_arbiter rx_arbiter (
	.clk	(clk),
	.reset	(reset),

	//interface to rx_update_fifo
	.rx_ext_update_q		(rx_ext_update_q),
	.rx_ext_update_rdreq		(rx_ext_update_rdreq),
	.rx_ext_update_empty		(rx_ext_update_empty),

	//interface to ext processors
	.rx_ext_update_q		(rx_ext_proc_update_data),
	.rx_ext_update_rdreq		(rx_ext_proc_update_wrreq),
	.rx_ext_update_empty		(rx_ext_proc_update_full)
);

generate
	for(i=0;i<MAX_NUM_EXT_PROCESSORS;i=i+1) begin


	end
endgenerate
*/

generate
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin:cc
accumulator_channel proc_mem_channel (
		.accumulator_wr_0_avalon_master_address       (accumulator_wr_avalon_master_address[i]),             
		.accumulator_wr_0_avalon_master_waitrequest   (accumulator_wr_avalon_master_waitrequest[i]),         
		.accumulator_wr_0_avalon_master_burstcount    (accumulator_wr_avalon_master_burstcount[i]),          
		.accumulator_wr_0_avalon_master_writedata     (accumulator_wr_avalon_master_writedata[i]),           
		.accumulator_wr_0_avalon_master_byteenable    (accumulator_wr_avalon_master_byteenable[i]),          
		.accumulator_wr_0_avalon_master_write         (accumulator_wr_avalon_master_write[i]),               
		
		.accumulator_rd_0_avalon_master_burstcount    (accumulator_rd_avalon_master_burstcount[i]),          
		.accumulator_rd_0_avalon_master_readdatavalid (accumulator_rd_avalon_master_readdatavalid[i]),       
		.accumulator_rd_0_avalon_master_readdata      (accumulator_rd_avalon_master_readdata[i]),            
		.accumulator_rd_0_avalon_master_byteenable    (accumulator_rd_avalon_master_byteenable[i]),          
		.accumulator_rd_0_avalon_master_read          (accumulator_rd_avalon_master_read[i]),                
		.accumulator_rd_0_avalon_master_address       (accumulator_rd_avalon_master_address[i]),             
		.accumulator_rd_0_avalon_master_waitrequest   (accumulator_rd_avalon_master_waitrequest[i]),         

		.accumulator_wr_0_control_write_base          (wr_control_write_base[i]),     
		.accumulator_wr_0_control_write_length        (wr_control_write_length[i]),   
		.accumulator_wr_0_control_fixed_location      (wr_control_fixed_location[i]), 
		.accumulator_wr_0_control_go                  (wr_control_go[i]),             
		.accumulator_wr_0_control_done                (wr_control_done[i]),           
	
		.accumulator_wr_0_user_buffer_full            (wr_user_buffer_full[i]),                  
		.accumulator_wr_0_user_buffer_input_data      (wr_user_buffer_data[i]), 
		.accumulator_wr_0_user_write_buffer	      (wr_user_write_buffer[i]),      

		.accumulator_rd_0_control_go                  (control_go[i]),
		.accumulator_rd_0_control_done                (control_done[i]),           
		.accumulator_rd_0_control_read_base           (control_read_base[i]),      
		.accumulator_rd_0_control_read_length         (control_read_length[i]),
		.accumulator_rd_0_control_early_done          (),
		.accumulator_rd_0_control_fixed_location      (control_fixed_location[i]),
				
		.accumulator_rd_0_user_read_buffer            (user_read_buffer[i]),
		.accumulator_rd_0_user_buffer_output_data     (user_buffer_data[i]),
		.accumulator_rd_0_user_data_available         (user_data_available[i]),
		
		.clk_clk	                              (clk),
		//.reset_reset_n                         	      (~reset)
		.reset_reset_n                         	      (~internal_system_reset)
	);
end
endgenerate

/*read channels for link read*/
generate
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin:lc
accumulator_channel linkread_mem_channel (
		
		.accumulator_rd_0_avalon_master_burstcount    (link_rd_avalon_master_burstcount[i]),          
		.accumulator_rd_0_avalon_master_readdatavalid (link_rd_avalon_master_readdatavalid[i]),       
		.accumulator_rd_0_avalon_master_readdata      (link_rd_avalon_master_readdata[i]),            
		.accumulator_rd_0_avalon_master_byteenable    (link_rd_avalon_master_byteenable[i]),          
		.accumulator_rd_0_avalon_master_read          (link_rd_avalon_master_read[i]),                
		.accumulator_rd_0_avalon_master_address       (link_rd_avalon_master_address[i]),             
		.accumulator_rd_0_avalon_master_waitrequest   (link_rd_avalon_master_waitrequest[i]),         

		.accumulator_rd_0_control_go                  (link_control_go[i]),
		.accumulator_rd_0_control_done                (link_control_done[i]),           
		.accumulator_rd_0_control_read_base           (link_control_read_base[i]),      
		.accumulator_rd_0_control_read_length         (link_control_read_length[i]),
		.accumulator_rd_0_control_early_done          (),
		.accumulator_rd_0_control_fixed_location      (link_control_fixed_location[i]),
				
		.accumulator_rd_0_user_read_buffer            (link_user_read_buffer[i]),
		.accumulator_rd_0_user_buffer_output_data     (link_user_buffer_data[i]),
		.accumulator_rd_0_user_data_available         (link_user_data_available[i]),
		
		.clk_clk	                              (clk),
		//.reset_reset_n                         	      (~reset)
		.reset_reset_n                         	      (~internal_system_reset)
	);
end
endgenerate


//the last bus wire(collection of wires) is reserved for external accumulate
//processor
wire [31:0] 		snoopy_bus_key_to_be_locked[PROCS_ON_SNOOPY_BUS-1:0]; //note that depth is not MAX_NUM_PROCS-1
wire	     		snoopy_bus_request[PROCS_ON_SNOOPY_BUS-1:0];
wire  			snoopy_bus_grant[PROCS_ON_SNOOPY_BUS-1:0];
wire	     		snoopy_bus_release[PROCS_ON_SNOOPY_BUS-1:0];


wire 			snoop_check;
wire [31:0]		snoop_bus;
wire			snoop_check_req[PROCS_ON_SNOOPY_BUS-1:0];

wire					add_conflict_proc_to_snoopy[PROCS_ON_SNOOPY_BUS-1:0];
wire 					add_conflict_snoopy_to_proc;
wire [PROCS_ON_SNOOPY_BUS-1:0]  	add_conflict_proc_to_snoopy_internal;

//the following wires are used only by normal processors
wire 			start_key_process;
wire			start_key_selection[MAX_NUM_PROCS-1:0];
wire [31:0]		threshold;
wire [31:0]		accum_value[MAX_NUM_PROCS-1:0];
wire [31:0]		total_accum_value;
wire [31:0]		inter_result[MAX_NUM_PROCS:0];


assign internal_system_reset=reset|compute_system_reset;


wire [log2(PROCS_ON_SNOOPY_BUS)-1:0] winner;	

assign snoop_bus  			= snoopy_bus_key_to_be_locked[winner];
assign snoop_check 			= snoop_check_req[winner];

generate
	for(i=0;i<PROCS_ON_SNOOPY_BUS;i=i+1) begin:confl
		assign add_conflict_proc_to_snoopy_internal[i]=add_conflict_proc_to_snoopy[i];
	end
endgenerate
assign add_conflict_snoopy_to_proc 	= |add_conflict_proc_to_snoopy_internal;

snoopy_bus_arbiter #(
	.MAX_NUM_PROCS(PROCS_ON_SNOOPY_BUS)
) snoopy_bus_arbiter (
	.clk	(clk),
	.reset			(internal_system_reset),

	//requests to access bus
	.snoopy_bus_request	(snoopy_bus_request),
	.snoopy_bus_grant	(snoopy_bus_grant),
	.snoopy_bus_release	(snoopy_bus_release),

	//the snoopy bus
	.winner			(winner),
	.max_fpga_procs		(max_fpga_procs)
);

top_k_fill #(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.MAX_NUM_PROCS(MAX_NUM_PROCS),
        .DATA_WIDTH(DATA_WIDTH),
        .DDR_BASE(DDR_BASE),
        .DDR_SIZE(DDR_SIZE), //1Gb
	.MAX_N_VALUES(MAX_N_VALUES),
	.MAX_K_VALUES(MAX_K_VALUES),
	.SORT_WIDTH(SORT_WIDTH)
	
) top_k_fill  (
	.clk		(clk),
	.reset		(internal_system_reset),

	//ddr
	.control_fixed_location	(topk_control_fixed_location),
	.control_read_base	(topk_control_read_base),	
	.control_read_length	(topk_control_read_length),
	.control_go		(topk_control_go),
	.control_done		(topk_control_done),

	.user_read_buffer	(topk_user_read_buffer),
	.user_buffer_data	(topk_user_buffer_output_data),
	.user_data_available	(topk_user_data_available),
	
	.num_keys		(num_keys_in),
	.start_update		(start_update),
	.max_n_values		(max_n_values),

	.start_key_process	(start_key_process),

   	.start_key_selection	(start_key_selection),
	.threshold		(threshold)
	

);
/*count iterations */
reg [31:0] it_count /*synthesis noprune*/;

always@(posedge clk) begin
	if(reset) begin
		it_count <= 0;
	end
	else begin
		if(start_key_selection[0]) begin
			it_count <= it_count+1;
		end
	end
end



collector #(
	.MAX_NUM_PROCS(MAX_NUM_PROCS)
) collect (
	.clk			(clk),
	.reset			(internal_system_reset),

	.accum_value		(accum_value),
	.iteration_accum_value	(iteration_accum_value),
	.max_fpga_procs		(max_fpga_procs)
);



wire [7:0] process_ext_updates;
assign process_ext_updates = ~proc_bit_mask;

generate 
for(i=0;i<MAX_NUM_PROCS;i=i+1) begin:p
processor #(
	.DEFAULT_READ_LENGTH(DEFAULT_READ_LENGTH),
        .DATA_WIDTH(DATA_WIDTH),
	.DDR_BASE(DDR_BASE), 
        .DDR_SIZE(DDR_SIZE), //1Gb
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
	.MAX_NUM_PROCS(MAX_NUM_PROCS),
	.MAX_LOCK_KEYS(MAX_LOCK_KEYS),
	.PROC_ID(i),
	.EXT_PROCESSOR(0)
) proc (
        //clocks and resets
        .clk 	(clk),
	.reset		(internal_system_reset),

	//write interface b/w update unit and main memory
   	.wr_control_fixed_location 	(wr_control_fixed_location[i]),
   	.wr_control_write_base 		(wr_control_write_base[i]),
  	.wr_control_write_length 	(wr_control_write_length[i]),
   	.wr_control_go 			(wr_control_go[i]),
   	.wr_control_done 		(wr_control_done[i]),

   	.wr_user_write_buffer 		(wr_user_write_buffer[i]),
   	.wr_user_buffer_data 		(wr_user_buffer_data[i]),
   	.wr_user_buffer_full 		(wr_user_buffer_full[i]),
	
	//read interface b/w update unit and main memory
	.control_fixed_location		(control_fixed_location[i]),
	.control_read_base		(control_read_base[i]),	
	.control_read_length		(control_read_length[i]),
	.control_go			(control_go[i]),
	.control_done			(control_done[i]),

	.user_read_buffer		(user_read_buffer[i]),
	.user_buffer_data		(user_buffer_data[i]),
	.user_data_available		(user_data_available[i]),

	//read interface b/w link reader and main memory
	.link_control_fixed_location	(link_control_fixed_location[i]),
	.link_control_read_base		(link_control_read_base[i]),	
	.link_control_read_length	(link_control_read_length[i]),
	.link_control_go		(link_control_go[i]),
	.link_control_done		(link_control_done[i]),

	.link_user_read_buffer		(link_user_read_buffer[i]),
	.link_user_buffer_data		(link_user_buffer_data[i]),
	.link_user_data_available	(link_user_data_available[i]),

	//interfaces b/w cache controller and snoopy bus
	.snoopy_bus_key_to_be_locked	(snoopy_bus_key_to_be_locked[i]),
	.snoopy_bus_request		(snoopy_bus_request[i]),
	.snoopy_bus_grant		(snoopy_bus_grant[i]),
	.snoopy_bus_release		(snoopy_bus_release[i]),
	.snoop_check_req		(snoop_check_req[i]),
	.add_conflict_snoopy_to_proc	(add_conflict_snoopy_to_proc),

	//interface b/w snooper and snoopy bus
	.snoop_check			(snoop_check),
	.snoop_bus			(snoop_bus),
	.add_conflict_proc_to_snoopy	(add_conflict_proc_to_snoopy[i]),

	//external fifo 
	.ext_fifo_data			(ext_fifo_data[i]),
	.ext_fifo_wrreq			(ext_fifo_wrreq[i]),
	.ext_fifo_full			(ext_fifo_full[i]),
	.process_ext_updates		(process_ext_updates[i]),

	//interfaces to rx ext fifo
	.rx_ext_update_q		(rx_ext_update_q[i]),
	.rx_ext_update_rdreq		(rx_ext_update_rdreq[i]),
	.rx_ext_update_empty		(rx_ext_update_empty[i]),
	
	//interface b/w update unit and top k selection circuit
	.start_key_process		(start_key_process),
        .start_key_selection		(start_key_selection[i]),

	//misc status signals to update unit
	.filter_threshold		(filter_threshold),
	.threshold			(threshold),
	.log_2_num_workers_in		(log_2_num_workers_in),
	.num_keys			(num_keys_in),
	.iteration_accum_value		(accum_value[i]),
	.start_update			(start_update),
	.shard_id			(shard_id),
	.max_fpga_procs			(max_fpga_procs),
	.algo_selection			(algo_selection)

       
);
end
endgenerate


endmodule

