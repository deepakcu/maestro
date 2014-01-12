`timescale 1ns/1ps

`define TEST2
module test_bench;

function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
endfunction // log2

wire [255:0] user_buffer_data;
wire user_data_available;
wire user_read_buffer;
reg start_update;
reg clk, reset_n;
reg flush_ddr;
wire [31:0] accum_value;
wire wr_done;
reg check_terminate;
initial
#0 clk = 1'b0;

initial begin
#0 reset_n = 1'b0;
#0 check_terminate = 1'b0;
#0  start_update = 1'b0;
#0  flush_ddr = 1'b0;
#20 reset_n = 1'b1;
#80 start_update = 1'b1;
//#100000 start_update = 1'b0;
//#100 check_terminate = 1'b1; 
//#20 check_terminate = 1'b0;
//#1000000 check_terminate = 1'b1; 
//#20 check_terminate = 1'b0;
//#1000000 check_terminate = 1'b1; 
//#20 check_terminate = 1'b0;

//#100000 start_update = 1'b0;



//#120 flush_ddr = 1'b1;
//#140 flush_ddr = 1'b0;

//#18000 flush_ddr = 1'b1;
//#20 flush_ddr = 1'b0;
//#18000 flush_ddr = 1'b1;
//#20 flush_ddr = 1'b0;
end

always
#10 clk = ~clk;

/*
test test (
                .compute_system_0_pause_update_export (1'b0),                  //                  compute_system_0_pause_update.export
                .compute_system_0_netfpga_out_rdy_export (1'b1),               //               compute_system_0_netfpga_out_rdy.export
                .compute_system_0_user_data_available(user_data_available),                  //                          compute_system_0_user.data_available
                .compute_system_0_user_read_buffer(user_read_buffer),                     //                                               .read_buffer
                .compute_system_0_user_buffer_data(user_buffer_data),                     //                                               .buffer_data
                .reset_reset_n(reset_n),                                         //                                          reset.reset_n
                .clk_clk(clk),                                               //                                            clk.clk
                .master_template_0_user_read_buffer(user_read_buffer),                    //                         master_template_0_user.read_buffer
                .master_template_0_user_buffer_output_data(user_buffer_data),             //                                               .buffer_output_data
                .master_template_0_user_data_available(user_data_available),                 //                                               .data_available
                .compute_system_0_start_update_export(start),                  //                  compute_system_0_start_update.export
                .compute_system_0_accumulator_local_waitrequest_export(1'b0)  // compute_system_0_accumulator_local_waitrequest.export
        );
		  */
		  
DE4_SOPC de4_sopc(
		.reset_n (reset_n),                                       //                   ext_clk_clk_in_reset.reset_n
		//.dram_read_dram_flush_export (flush_ddr),             //             compute_system_0_flush_ddr.export
		//.compute_system_0_iteration_accum_value_export (accum_value), // compute_system_0_iteration_accum_value.export
		//.compute_system_0_netfpga_if_wr_done (wr_done),           //            compute_system_0_netfpga_if.wr_done
		//.compute_system_0_netfpga_if_worker_id (),         //                                       .worker_id
		//.compute_system_0_netfpga_if_data (),              //                                       .data
		//.compute_system_0_netfpga_if_wr(),                //                                       .wr
		//.compute_system_0_netfpga_if_rdy (1'b1),               //                                       .rdy
		.ext_clk_clk_in_clk (clk),                            //                         ext_clk_clk_in.clk
		.compute_system_0_start_update_export(start_update)           //          compute_system_0_start_update.export
		//.ethernet_port_interface_0_check_terminate_export(check_terminate)
	);		  
		  







endmodule
