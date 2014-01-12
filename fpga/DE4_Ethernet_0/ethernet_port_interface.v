module ethernet_port_interface #(
	parameter WORKER_ADDR_WIDTH=2,
	parameter TOTAL_DATA=8
)
(
		input  wire        clk,                           
		input  wire        reset,                          
		
		input  wire [26:0]  control_port_address,     
		input  wire         control_port_read,        
		output wire [31:0]  control_port_readdata,    
		input  wire         control_port_write,       
		input  wire [31:0]  control_port_writedata,   
		output wire         control_port_waitrequest, 
		
		input  wire [7:0]  sink_data0,             
		output wire        sink_ready0,            
		input  wire        sink_valid0,           
		input  wire [5:0]  sink_error0,            
		input  wire        sink_startofpacket0,    
		input  wire        sink_endofpacket0,      
		
		output wire [7:0]  source_data0,             
		input  wire        source_ready0,               
		output wire        source_valid0,              
		output wire        source_error0,              
		output wire        source_startofpacket0,       
		output wire        source_endofpacket0,		

		input  wire [7:0]  sink_data1,             
		output wire        sink_ready1,            
		input  wire        sink_valid1,           
		input  wire [5:0]  sink_error1,            
		input  wire        sink_startofpacket1,    
		input  wire        sink_endofpacket1,      
		
		output wire [7:0]  source_data1,             
		input  wire        source_ready1,               
		output wire        source_valid1,              
		output wire        source_error1,              
		output wire        source_startofpacket1,       
		output wire        source_endofpacket1,		

		input  wire [7:0]  sink_data2,             
		output wire        sink_ready2,            
		input  wire        sink_valid2,           
		input  wire [5:0]  sink_error2,            
		input  wire        sink_startofpacket2,    
		input  wire        sink_endofpacket2,      
		
		output wire [7:0]  source_data2,             
		input  wire        source_ready2,               
		output wire        source_valid2,              
		output wire        source_error2,              
		output wire        source_startofpacket2,       
		output wire        source_endofpacket2,		

		input  wire [7:0]  sink_data3,             
		output wire        sink_ready3,            
		input  wire        sink_valid3,           
		input  wire [5:0]  sink_error3,            
		input  wire        sink_startofpacket3,    
		input  wire        sink_endofpacket3,      
		
		output wire [7:0]  source_data3,             
		input  wire        source_ready3,               
		output wire        source_valid3,              
		output wire        source_error3,              
		output wire        source_startofpacket3,       
		output wire        source_endofpacket3,		

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

//write interface to DDR (used by load data function)
output [63:0] dram_fifo_writedata,
output        dram_fifo_write,
input         dram_fifo_full,

//read interface from DDR (used by flush data function)
input [63:0]  dram_fifo_readdata,
output        dram_fifo_read,
input         dram_fifo_empty,

output	      start_update,
output	      flush_ddr,
output	      start_load,
input [31:0]  iteration_accum_value,
output [31:0] num_keys,
output [31:0] log_2_num_workers, //returns the log2(number of workers) - useful for mask calculation in key hashing
output [31:0]   shard_id,
output [31:0]   max_n_values,
output [31:0]   filter_threshold,
output 		compute_system_reset,
output [3:0]    max_fpga_procs,
output	        algo_selection,

output [7:0]  proc_bit_mask
);

////////////New wires/////////////

/*
wire [7:0]  sink_data1;             
		 wire        sink_ready1;           
		  wire        sink_valid1;            
		  wire [5:0]  sink_error1;            
		  wire        sink_startofpacket1;  
		  wire        sink_endofpacket1;      
		
		 wire [7:0]  source_data1;                
		  wire        source_ready1;               
		 wire        source_valid1;               
		 wire        source_error1;              
		 wire        source_startofpacket1;       
		 wire        source_endofpacket1;         
		
		  wire [7:0]  sink_data2;             
		 wire        sink_ready2;            
		  wire        sink_valid2;            
		  wire [5:0]  sink_error2;           
		  wire        sink_startofpacket2;  
		  wire        sink_endofpacket2;      
		
		 wire [7:0]  source_data2;                
		  wire        source_ready2;               
		 wire        source_valid2;               
		 wire        source_error2;               
		 wire        source_startofpacket2;     
		 wire        source_endofpacket2;  
		
		  wire [7:0]  sink_data3;             
		 wire        sink_ready3;            
		  wire        sink_valid3;            
		  wire [5:0]  sink_error3;            
		  wire        sink_startofpacket3;   
		  wire        sink_endofpacket3;      
		
		 wire [7:0]  source_data3;               
		  wire        source_ready3;              
		 wire        source_valid3;            
		 wire        source_error3;           
		 wire        source_startofpacket3;       
		 wire        source_endofpacket3;        
*/
		
		  wire	   	txs_chip_select;
		  wire		txs_read;
		  wire 		txs_write;
		  wire [24:0]	txs_address;
		  wire [9:0]	txs_burst_count;
		  wire [63:0]	txs_writedata;
		  wire [7:0]	txs_byteenable;
		 	wire 		txs_read_valid;
		 	wire [63:0]	txs_readdata;
		 	wire 		txs_wait_request;
		
		// wire 			user_sw;
		
		 	wire 		rxm_read_bar_0_1;
		 	wire     	rxm_write_bar_0_1;
		 	wire [24:0] rxm_address_bar_0_1;
		 	wire [31:0]	rxm_writedata_bar_0_1;
		  wire 		rxm_wait_request_bar_0_1;
		  wire [31:0] rxm_readdata_bar_0_1;
		  wire 		rxm_read_valid_bar_0_1;
		
		
		 	wire 		rxm_read_bar_1;
		 	wire     	rxm_write_bar_1;
		 	wire [24:0] rxm_address_bar_1;
		 	wire [31:0]	rxm_writedata_bar_1;
		  wire 		rxm_wait_request_bar_1;
		  wire [31:0] rxm_readdata_bar_1;
		  wire 		rxm_read_valid_bar_1;
		
			wire 		rxm_read_bar_1_out;
			wire     	rxm_write_bar_1_out;
			wire [31:0] rxm_address_bar_1_out;
			wire [31:0] rxm_writedata_bar_1_out;
		 	wire 		rxm_wait_request_bar_1_in;
		  	wire [31:0] rxm_readdata_bar_1_in;
		 	wire 	    rxm_read_valid_bar_1_in;
		  
		




/////////New wires end///////




	wire 			user_sw;
	assign user_sw = 1'b1;
	wire [27:0]		rxm_address_bar_1_out_shift;
	wire [26:0] 	MM_port_address;
	wire 			MM_port_read;
	wire [31:0] 	MM_port_readdata;
	wire 			MM_port_write;
	wire [31:0]		MM_port_writedata;
	wire 			MM_port_waitrequest;
	wire 			MM_port_readdata_valid;	
	wire [26:0] 	control_port_address_rxm_shift;	
	wire [31:0] 	rxm_port_readdata;
	reg 			sink_error0_in_reg;
	reg 			sink_error1_in_reg;
	reg 			sink_error2_in_reg;
	reg 			sink_error3_in_reg;
	reg 			sink_ready0_reg;
	reg 			sink_ready1_reg;
	reg 			sink_ready2_reg;
	reg 			sink_ready3_reg;
		
	assign rxm_address_bar_1_out_shift 							= (rxm_address_bar_1 << 2);
	assign rxm_read_bar_1_out 									= rxm_read_bar_1;
	assign rxm_write_bar_1_out 									= rxm_write_bar_1;
	assign rxm_address_bar_1_out 								= ({1'b1,2'b00,rxm_address_bar_1_out_shift[26:20],4'b0000,rxm_address_bar_1_out_shift[19:4]});
	assign rxm_writedata_bar_1_out 								= rxm_writedata_bar_1;
	assign rxm_wait_request_bar_1 								= rxm_wait_request_bar_1_in;
	assign rxm_readdata_bar_1 									= rxm_readdata_bar_1_in;
	assign rxm_read_valid_bar_1 								= rxm_read_valid_bar_1_in;
	assign control_port_address_rxm_shift 						= (rxm_address_bar_0_1 << 2);	
		
	assign MM_port_address 										= (user_sw)?(control_port_address):({control_port_address_rxm_shift[26:20],4'b0000,control_port_address_rxm_shift[19:4]});
	assign MM_port_read 										= (user_sw)?control_port_read:rxm_read_bar_0_1;
	assign MM_port_write 										= (user_sw)?control_port_write:rxm_write_bar_0_1;
	assign MM_port_writedata 									= (user_sw)?control_port_writedata:rxm_writedata_bar_0_1;
	
	assign  control_port_readdata 								= MM_port_readdata;
	assign  control_port_waitrequest 							= MM_port_waitrequest;
		
	assign rxm_readdata_bar_0_1 								= (user_sw)?32'b0:rxm_port_readdata;
	assign rxm_read_valid_bar_0_1 								= (user_sw)?1'b0:MM_port_readdata_valid;
	assign rxm_wait_request_bar_0_1 							= (user_sw)?1'b0:MM_port_waitrequest;
	
	

		
		
	nf2_core #( .WORKER_ADDR_WIDTH(WORKER_ADDR_WIDTH),
		    .TOTAL_DATA(TOTAL_DATA))
nf2_core   (	
		.control_port_address(MM_port_address),   
		.control_port_read(MM_port_read),       
		.control_port_readdata(MM_port_readdata),    
		.control_port_write(MM_port_write),      
		.control_port_writedata(MM_port_writedata),  
		.control_port_waitrequest(MM_port_waitrequest), 
		.control_port_read_datavalid(MM_port_readdata_valid),
		.rxm_port_readdata(rxm_port_readdata),
	
		.gmac_tx_data_1_out(source_data1),
		.gmac_tx_dvld_1_out(source_valid1),
		.gmac_tx_ack_1_out(source_ready1),
		.end_of_packet_1_out(source_endofpacket1),
		.start_of_packet_1_out(source_startofpacket1),
		  
		.gmac_rx_data_1_in(sink_data1),
		.gmac_rx_dvld_1_in(sink_valid1),
		.gmac_rx_frame_error_1_in(sink_error1_in), 
		
		.gmac_tx_data_2_out(source_data2),
		.gmac_tx_dvld_2_out(source_valid2),
		.gmac_tx_ack_2_out(source_ready2),
		.end_of_packet_2_out(source_endofpacket2),
		.start_of_packet_2_out(source_startofpacket2),
		  
		.gmac_rx_data_2_in(sink_data2),
		.gmac_rx_dvld_2_in(sink_valid2),
		.gmac_rx_frame_error_2_in(sink_error2_in),
		
		.gmac_tx_data_3_out(source_data3),
		.gmac_tx_dvld_3_out(source_valid3),
		.gmac_tx_ack_3_out(source_ready3),
		.end_of_packet_3_out(source_endofpacket3),
		.start_of_packet_3_out(source_startofpacket3),
		  
		.gmac_rx_data_3_in(sink_data3),
		.gmac_rx_dvld_3_in(sink_valid3),
		.gmac_rx_frame_error_3_in(sink_error3_in), 
		
		.gmac_tx_data_0_out(source_data0),
		.gmac_tx_dvld_0_out(source_valid0),
		.gmac_tx_ack_0_out(source_ready0),
		.end_of_packet_0_out(source_endofpacket0),
		.start_of_packet_0_out(source_startofpacket0),
		  
		.gmac_rx_data_0_in(sink_data0),
		.gmac_rx_dvld_0_in(sink_valid0),
		.gmac_rx_frame_error_0_in(sink_error0_in), 
		
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

//write interface to DDR (used by load data function)
.dram_fifo_writedata	(dram_fifo_writedata),
.dram_fifo_write	(dram_fifo_write),
.dram_fifo_full		(dram_fifo_full),

//read interface from DDR (used by flush data function)
.dram_fifo_readdata	(dram_fifo_readdata),
.dram_fifo_read		(dram_fifo_read),
.dram_fifo_empty	(dram_fifo_empty),

.start_update	(start_update),
.flush_ddr	(flush_ddr),
.start_load	(start_load),
.iteration_accum_value (iteration_accum_value),
.compute_system_reset 	(compute_system_reset),

.num_keys (num_keys),
.log_2_num_workers (log_2_num_workers),
.shard_id (shard_id),
.max_fpga_procs (max_fpga_procs),
.proc_bit_mask(proc_bit_mask),
.algo_selection (algo_selection),
.max_n_values (max_n_values),
.filter_threshold (filter_threshold),

      .core_clk_int(clk),
      .reset(reset)    

   );
	
	always@ (*) begin
		if(sink_error0 == 6'b0)begin
			sink_error0_in_reg = 1'b0;
		end
		else begin
			sink_error0_in_reg = 1'b1;
		end
	end
	always@(*) begin
		if(sink_error1 == 6'b0)begin
			sink_error1_in_reg = 1'b0;
		end
		else begin
			sink_error1_in_reg = 1'b1;
		end
	end
		always@(*) begin
		if(sink_error2 == 6'b0)begin
			sink_error2_in_reg = 1'b0;
		end
		else begin
			sink_error2_in_reg = 1'b1;
		end
	end
		always@(*) begin
		if(sink_error3 == 6'b0)begin
			sink_error3_in_reg = 1'b0;
		end
		else begin
			sink_error3_in_reg = 1'b1;
		end
	end
	
	assign sink_error0_in = sink_error0_in_reg;
	assign sink_error1_in = sink_error1_in_reg;
	assign sink_error2_in = sink_error2_in_reg;
	assign sink_error3_in = sink_error3_in_reg;

	assign source_error0 = 1'b0;
	assign source_error1 = 1'b0;
	assign source_error2 = 1'b0;
	assign source_error3 = 1'b0;

		always @(posedge clk) begin
			if (reset) begin
				sink_ready0_reg = 1'b0;

			end
			else begin
			 sink_ready0_reg = 1'b1;
			 end
		end
		
		always @(posedge clk) begin
			if (reset) begin
				sink_ready1_reg = 1'b0;

			end
			else begin
			 sink_ready1_reg = 1'b1;
			 end
		end	
		
		always @(posedge clk) begin
			if (reset) begin
				sink_ready2_reg = 1'b0;

			end
			else begin
			 sink_ready2_reg = 1'b1;
			 end
		end
		
		always @(posedge clk) begin
			if (reset) begin
				sink_ready3_reg = 1'b0;

			end
			else begin
			 sink_ready3_reg = 1'b1;
			 end
		end
	
	assign sink_ready0 = sink_ready0_reg;
	assign sink_ready1 = sink_ready1_reg;
	assign sink_ready2 = sink_ready2_reg;
	assign sink_ready3 = sink_ready3_reg;	

endmodule		
