
//Defines all commands between FPGA and Maiter here
//These defines will be globally applied
//deepak - fix bug 4'h->8'h
`define START_LOAD              	8'h1 
`define LOAD_DATA               	8'h2
`define END_LOAD                	8'h3 
`define WORKER_TO_FPGA_PUT_REQUEST    	8'h4
`define START_UPDATE            	8'h5
`define END_UPDATE            		8'h6
`define START_CHECK_TERMINATE   	8'h7
`define START_FLUSH_DATA        	8'h8
//the following are replies from FPGA to worker node
`define FPGA_TO_WORKER_PUT_REQUEST 	8'h9 
`define FLUSH_DATA			8'ha 
`define	CHECK_TERMINATE			8'hb 


