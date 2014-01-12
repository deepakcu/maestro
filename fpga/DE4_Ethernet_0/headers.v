wire [63:0] tcheck_header[7:0];
wire [63:0] flush_header[7:0];
wire [63:0] put_header[7:0];

wire [63:0] tcheck_netfpga_header;
wire [63:0] flush_netfpga_header;
wire [63:0] put_netfpga_header;

assign tcheck_netfpga_header = 64'h0001000800010040;
assign flush_netfpga_header = 64'h0001000800010040;
assign put_netfpga_header = 64'h0001009c000104e0;

assign put_header[0] = 64'h0014d1176bee004e; //bytes 0-7 
assign put_header[1] = 64'h4632430008004510; //bytes 8-15
assign put_header[2] = 64'h04d2d43100001411; //bytes 16-23
assign put_header[3] = 64'hadd6140101010a01; //bytes 24-31
assign put_header[4] = 64'h0101001e001e04be; //bytes 32-39
assign put_header[5] = 64'h0000090000000000; //bytes 40-47
assign put_header[6] = 64'h0000000000000000; //bytes 48-55
//data to start from bytes 56-64 etc.. (must have atleast one data) - total length = 64 bytes

assign flush_header[0] = 64'h0014d1176bee004e;
assign flush_header[1] = 64'h4632430008004510;
assign flush_header[2] = 64'h0032d43100001411;
assign flush_header[3] = 64'hb276140101010a01;
assign flush_header[4] = 64'h0101001e001e001e;
assign flush_header[5] = 64'h00000a0000000000;
assign flush_header[6] = 64'h0000000000000000;
//data to start from bytes 56-64 etc.. (must have atleast one data) - min total length = 64 bytes

assign tcheck_header[0] = 64'h0014d1176bee004e; //bytes 0-7
assign tcheck_header[1] = 64'h4632430008004510; //bytes 8-15
assign tcheck_header[2] = 64'h0032d43100001411; //bytes 16-23
assign tcheck_header[3] = 64'hb276140101010a01; //bytes 24-31
assign tcheck_header[4] = 64'h0101001e001e001e; //bytes 32-39
assign tcheck_header[5] = 64'h00000b0000000000; //bytes 40-47

assign tcheck_header[6] = 64'h0000000000000000; //bytes 48-55
//data to start from bytes 56-64 etc.. (must have atleast one data) - total length = 64 bytes
