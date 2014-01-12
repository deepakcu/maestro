

/*

Processor places key to be locked on proc_key and asserts proc_obtain_key
for 1 cycle. It must then wait for proc_key_grant from coherence 
controller. On getting proc_key_grant, processor can safely
go ahead with the update procedure. After the procedure is complete,
it must assert the proc_key_release

Coherence controller waits for proc_obtain_key from processor. When
request is received, it places the request on the snoopy bus 
request signals. When grant signal is received, it checks the 
add_conflict lines for any potential conflict. If no conflict is 
detected, it sets the locked_key to the requested key and sets
valid bit to true. It then asserts
the proc_key_grant signal. It then waits for processor to release
the key. On  proc_key_release going high, coherence controller invalidates
the key.

*/


module coherence_controller #(
	parameter MAX_NUM_PROCS=4,
	parameter MAX_LOCK_KEYS=4
) (
	input clk,
	input reset,

	//signals to processor
	input [31:0] 		proc_key,
	input 			proc_obtain_key,
	output reg   		proc_key_grant,
	output reg		proc_key_blocked,
	input 	     		proc_key_release,
	output reg		proc_key_release_ack,
	output wire		locks_available,
	
	//requests to access bus
	output reg [31:0] 	snoopy_bus_key_to_be_locked,
	output reg 		snoopy_bus_request,
	input 			snoopy_bus_grant,
	output reg 		snoopy_bus_release,
	output reg		snoop_check_req,
	input wire		add_conflict_snoopy_to_proc,

	//interface b/w snooper and cache controller
	output wire [31:0] 	locked_key_export[MAX_LOCK_KEYS-1:0]
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


localparam WAIT_CYCLES=20; //retry bus lock after 20 cycles
localparam NUM_STATES		=7;
localparam IDLE			=0;
localparam WAIT_SNOOPY_LOCK	=1;
localparam RESPONSE_CYCLE	=2;
localparam CHECK_CONFLICT	=3;
localparam BUS_RELEASE		=4;
localparam RELEASE_KEY		=5;
localparam WAIT			=6;

reg snoopy_bus_request_next;
reg snoopy_bus_release_next;

reg [31:0] 			snoopy_bus_key_to_be_locked_next;
reg [31:0] 			locked_key[MAX_LOCK_KEYS-1:0];
reg [31:0] 			locked_key_next[MAX_LOCK_KEYS-1:0];
reg 				proc_key_grant_next;
reg				proc_key_blocked_next;
reg				proc_key_release_ack_next;
reg [log2(NUM_STATES)-1:0]	state, state_next;
reg				snoop_check_req_next;

reg [log2(MAX_LOCK_KEYS)-1:0]	lock_ptr, lock_ptr_next;
reg [log2(MAX_LOCK_KEYS)-1:0]	unlock_ptr, unlock_ptr_next;
wire [log2(MAX_LOCK_KEYS)-1:0]	lock_ptr_plus_1;

//assign lock_ptr_plus_1 = (lock_ptr+1)&{log2(MAX_LOCK_KEYS){1'b1}};
//assign locks_available = (lock_ptr_plus_1==unlock_ptr)?1'b0:1'b1;

reg [2:0] fifo_val_counter, fifo_val_counter_next;

assign locks_available = (fifo_val_counter<4)?1'b1:1'b0;

//assert (lock_ptr_plus_1 == unlock_ptr) $display ("All lock keys utilized!!");
genvar i;
generate
	for(i=0;i<MAX_LOCK_KEYS;i=i+1) begin:t
		assign locked_key_export[i]=locked_key[i];
	end
endgenerate



always@(*)
begin

	snoopy_bus_request_next = snoopy_bus_request;
	snoopy_bus_release_next = 0;
	snoop_check_req_next    = 0;

	snoopy_bus_key_to_be_locked_next = snoopy_bus_key_to_be_locked;
	locked_key_next[0] = locked_key[0];
	locked_key_next[1] = locked_key[1];
	locked_key_next[2] = locked_key[2];
	locked_key_next[3] = locked_key[3];

	proc_key_grant_next = 0;
	proc_key_blocked_next = 0;
	proc_key_release_ack_next = 0;

	state_next = state;
	
	lock_ptr_next = lock_ptr;
	unlock_ptr_next = unlock_ptr;
	fifo_val_counter_next = fifo_val_counter;

	case(state)
		IDLE: begin
			if(proc_key_release) begin
				locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
				unlock_ptr_next	= unlock_ptr+1;
				fifo_val_counter_next = fifo_val_counter-1;
			end
			else if(proc_obtain_key) begin
				snoopy_bus_request_next = 1'b1;
				state_next = WAIT_SNOOPY_LOCK;
			end
			else
				state_next = IDLE;
		end

		WAIT_SNOOPY_LOCK:begin
			if(snoopy_bus_grant) begin
				if(proc_key_release) begin
					locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
					unlock_ptr_next	= unlock_ptr+1;
					fifo_val_counter_next = fifo_val_counter-1;
				end
				snoopy_bus_key_to_be_locked_next 	= proc_key;
				snoop_check_req_next			= 1'b1;
				state_next 				= RESPONSE_CYCLE;
			end
			else if(proc_key_release) begin
				locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
				unlock_ptr_next	= unlock_ptr+1;
				fifo_val_counter_next = fifo_val_counter-1;
			end
		end

		RESPONSE_CYCLE:begin
			state_next = CHECK_CONFLICT;
			if(proc_key_release) begin
				locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
				unlock_ptr_next	= unlock_ptr+1;
				fifo_val_counter_next = fifo_val_counter-1;
			end
		end

		CHECK_CONFLICT:begin
			if(add_conflict_snoopy_to_proc) begin
				if(proc_key_release) begin
					locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
					unlock_ptr_next	= unlock_ptr+1;
					fifo_val_counter_next = fifo_val_counter-1;
				end
				snoopy_bus_release_next = 1'b1;			
				proc_key_blocked_next = 1'b1;
				state_next = WAIT;
			end
			else begin
				if(proc_key_release) begin
					locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
					unlock_ptr_next	= unlock_ptr+1;
					fifo_val_counter_next = fifo_val_counter-1;
				end
				else begin
					locked_key_next[lock_ptr] = proc_key;
					lock_ptr_next=lock_ptr+1;
					proc_key_grant_next = 1'b1;	
					fifo_val_counter_next = fifo_val_counter+1;
					state_next = BUS_RELEASE;
				end
			end
		end

		BUS_RELEASE:begin
			if(proc_key_release) begin
				locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
				unlock_ptr_next	= unlock_ptr+1;
				fifo_val_counter_next = fifo_val_counter-1;
			end
			
			snoopy_bus_request_next = 1'b0;
			snoopy_bus_release_next = 1'b1;
			state_next = IDLE;
		end

		RELEASE_KEY: begin
			locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
			unlock_ptr_next	= unlock_ptr+1;
			fifo_val_counter_next = fifo_val_counter-1;
			state_next = IDLE;
		end

		WAIT: begin
			if(proc_key_release) begin
				locked_key_next[unlock_ptr] = 32'hFFFFFFFF;
				unlock_ptr_next	= unlock_ptr+1;
				fifo_val_counter_next = fifo_val_counter-1;
			end
			state_next = IDLE;
		end
	endcase
end

/*
always@(posedge clk) 
begin
	case({proc_key_release,

	if(proc_key_release) begin
		locked_key[unlock_ptr] 	<= 32'hFFFFFFFF;
		unlock_ptr		<= unlock_ptr+1;
		fifo_val_counter 	<= fifo_val_counter-1;
	end
	else if(insert) begin
		locked_key[lock_ptr] 	<= proc_key;
		lock_ptr		<= lock_ptr+1;
		fifo_val_counter 	<= fifo_val_counter+1;

	end

end
*/

always@(posedge clk) 
begin
	if(reset) begin

		snoopy_bus_request <= 0;
		snoopy_bus_release <= 0;
		snoop_check_req	   <= 0;

		snoopy_bus_key_to_be_locked <= 0;
		locked_key[0] <= 32'hFFFFFFFF;
		locked_key[1] <= 32'hFFFFFFFF;
		locked_key[2] <= 32'hFFFFFFFF;
		locked_key[3] <= 32'hFFFFFFFF;

		proc_key_grant <= 0;
		proc_key_blocked <= 0;
		proc_key_release_ack <= 0;
		
		lock_ptr <= 0;
		unlock_ptr <= 0;

		fifo_val_counter <= 0;
		state <= IDLE;
	end
	else begin
		snoopy_bus_request <= snoopy_bus_request_next;
		snoopy_bus_release <= snoopy_bus_release_next;
		snoop_check_req	   <= snoop_check_req_next;

		snoopy_bus_key_to_be_locked <= snoopy_bus_key_to_be_locked_next;

		locked_key[0] <= locked_key_next[0];
		locked_key[1] <= locked_key_next[1];
		locked_key[2] <= locked_key_next[2];
		locked_key[3] <= locked_key_next[3];
		
		proc_key_grant <= proc_key_grant_next;
		proc_key_blocked <= proc_key_blocked_next;
		proc_key_release_ack <= proc_key_release_ack_next;
		
		lock_ptr <= lock_ptr_next;
		unlock_ptr <= unlock_ptr_next;

		fifo_val_counter <= fifo_val_counter_next;
		state <= state_next;
	end
end

endmodule

