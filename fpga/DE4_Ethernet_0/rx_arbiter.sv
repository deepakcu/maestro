module rx_arbiter #(
	parameter MAX_NUM_PROCS=2
)  (
	input clk,
	input reset,

	input [63:0]	rx_ext_update_q,
	output reg	rx_ext_update_rdreq,
	input		rx_ext_update_empty,

	output [63:0]	rx_ext_proc_update_data,
	output reg [MAX_NUM_PROCS-1:0] rx_ext_proc_update_wrreq,
	input	[MAX_NUM_PROCS-1:0]		rx_ext_proc_update_full	

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



localparam NUM_STATES=2;
localparam IDLE=0;
localparam WRITE=1;

reg[log2(NUM_STATES)-1:0] state, state_next;
reg 			  rx_ext_update_rdreq_next;
reg [log2(MAX_NUM_PROCS)-1:0] fifo_tgt;
reg [log2(MAX_NUM_PROCS)-1:0] fifo_tgt_next;
reg [MAX_NUM_PROCS-1:0] rx_ext_proc_update_wrreq_next;
reg rx_ext_proc_update_data_next[MAX_NUM_PROCS-1:0];



assign rx_ext_proc_update_data = rx_ext_update_q;


always@(*) begin

	state_next			= state;			
	fifo_tgt_next			= fifo_tgt;		
	rx_ext_update_rdreq_next	= 0;    
	rx_ext_proc_update_wrreq_next	= 0;        
	
	case(state)
		IDLE:begin
			if(!rx_ext_update_empty) begin
				if(!rx_ext_proc_update_full[fifo_tgt]) begin
					rx_ext_update_rdreq_next = 1'b1;
					state_next = WRITE;
				end
				else begin
					fifo_tgt_next = fifo_tgt+2;
				end
			end
		end
	
		WRITE:begin
			rx_ext_proc_update_wrreq_next[fifo_tgt] = 1;
			fifo_tgt_next = fifo_tgt+2;
			state_next = IDLE;
		end
	endcase
end


always@(posedge clk) begin
	if(reset) begin
		state 			<= IDLE;
		fifo_tgt		<= 1;
		rx_ext_update_rdreq	<= 0;
		rx_ext_proc_update_wrreq<= 0;
		
	end
	else begin
		state			<= state_next;
		fifo_tgt		<= fifo_tgt_next;
		rx_ext_update_rdreq	<= rx_ext_update_rdreq_next;
		rx_ext_proc_update_wrreq<= rx_ext_proc_update_wrreq_next;
		
	end
end






endmodule
