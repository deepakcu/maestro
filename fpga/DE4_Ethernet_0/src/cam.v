/*******************************************************************************
 *                                                                             *
 *                  Copyright (C) 2009 Altera Corporation                      *
 *                                                                             *
 * Altera  products  are  protected  under  numerous U.S. and foreign patents, *
 * maskwork rights, copyrights and other intellectual property laws.           *
 *                                                                             *
 * This  reference  design  file,  and  your  use  thereof,  is subject to and *
 * governed  by  the  terms  and conditions of the applicable Altera Reference *
 * Design  License  Agreement  (either  as  signed  by you, agreed by you upon *
 * download  or  as  a "click-through" agreement upon installation andor found *
 * at www.altera.com).  By using this reference design file, you indicate your *
 * acceptance of such terms and conditions between you and Altera Corporation. *
 * In  the event that you do not agree with such terms and conditions, you may *
 * not  use  the  reference design file and please promptly destroy any copies *
 * you have made.                                                              *
 *                                                                             *
 * This  reference design file is being provided on an "as-is" basis and as an *
 * accommodation  and  therefore all warranties, representations or guarantees *
 * of  any  kind  (whether  express,  implied or statutory) including, without *
 * limitation, warranties of merchantability, non-infringement, or fitness for *
 * a  particular  purpose, are specifically disclaimed.  By making this refer- *
 * ence  design  file  available, Altera expressly does not recommend, suggest *
 * or  require that this reference design file be used in combination with any *
 * other product not provided by Altera.                                       *
 *                                                                             *
 * Module Name: cam                     File Name: cam.v                       *
 *                                                                             *
 * Module Function: This module implements "n"-entry "m"-bit key Content-      *
 *                  Addressable Memory (CAM), or CAMnxm.   The user need only  *
 *                  enter "n" (# of entries) and "m" (# of bits in key) to     *
 *                  create the CAM.    This is for Cyclone/Stratix III/IV      *
 *                  Families.                                                  *
 *                                                                             *
 * Modules Used:                                                               *
 *          erase_keys          Control for storing keys for erasure           *
 *          dpram               M9K RAM blocks used for CAM                    *
 *          prior_enc           Priority encoder                               *
 *          multi_bit_check     Multiple entries for same key checker          *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *          ENCODED_OUT         Select for optional encoded key address output *
 *          MULTI_MATCH_OUT     Select for optional multi-key match output     *
 *          FAMILY              Cyclone III/IV, or Stratix III/IV              *
 *          ENTRIES             Number of key entries in CAM (minimum of 2)    *
 *          KEY                 Number of bits in key in CAM (minimum of 4)    *
 *                                                                             *
 *      (Local)                                                                *
 *          INDEX               # of address bits to address ENTRIES           *
 *          SECTIONS            # of dpram instances per KEY slice             *
 *          SLICES              # of partitions of KEY to cover full range     *
 *          SEC_KEY             # of bits of KEY per SECTION                   *
 *          SEC_ENTRY           # of ENTRIES per SECTION                       *
 *          SEC_INDEX           # of address bits for SECTION ENTRIES          *
 *          SEC_ADDR            # of address bits to dpram instances           *
 *          KEY_MOD             # of left over bits of KEY in last SLICE       *
 *          SEC_MOD             # of left over bits of INDEX in last SECTION   *
 *          PAD_ENTRY           # of ENTRIES padded so all sections have the   *
 *                                  same number of SEC_ENTRY                   *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 08/22/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      09/22/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *  * Revision 1.1      10/20/2010      Jim Schwalbe                           *
 *      - Added a pipeline register to wr_erase_n and wr_key going to the      *
 *        dpram (CAM).                                                         *
 *      - Gated match with rd_en so only get a match when a lookup performed.  *
 *                                                                             *
 ******************************************************************************/

module cam (
                reset,              // Async reset
                wr_clk,             // Port A - Write Clock
                wr_en,              // Port A - Write Enable
                wr_key,             // Port A - Upper Write Address (CAM Key)
                wr_index,           // Port A - Lower Write Address (CAM Entry)
                wr_erase_n,         // Port A - Write Data (1=add, 0=erase)
                rd_clk,             // Port B - Read Clock
                rd_en,              // Port B - Read Enable
                rd_key,             // Port B - Read Address (CAM Key)
                one_hot_addr,       // One-hot data output (CAM Entry)
                match_addr,         // Encoded data output (CAM Entry)
                match,              // Indicator for CAM Entry Match
                multi_match,        // Indicator for multiple CAM Entry Match
                index_reg,          // CAM Entry scorecard register output
                cam_full,           // CAM Full (exceeded # of ENTRIES) indicator
                multi_index         // Indicator for multiple keys at same index
                );

// Options
`define         ENCODED_OUT
`define         MULTI_MATCH_OUT

// Target FPGA Family
parameter       FAMILY      = "Stratix IV";

// Enter Entries (m) and Key (n) for an m-Entry n-bit CAM (or CAMmxn)
parameter       ENTRIES     = 32;              // Minimum of 2
parameter       KEY         = 32;               // Minimum of 4

// All other parameters are calculated from ENTRIES and KEY.  DO NOT CHANGE.
// CAM Index & Sections
localparam      INDEX       = log2(ENTRIES);
localparam      SECTIONS    = ceil(ENTRIES,32);

// CAM Slices
localparam      SLICES      = ceil(KEY,(13-INDEX+log2(SECTIONS)));

// Section Key and Section Entries
localparam      SEC_KEY     = ceil(KEY,SLICES);
localparam      KEY_MOD     = KEY % SEC_KEY;
localparam      SEC_ENTRY   = ceil(ENTRIES,SECTIONS);
localparam      SEC_INDEX   = log2(SEC_ENTRY);
localparam      SEC_ADDR    = SEC_INDEX + SEC_KEY;
localparam      SEC_MOD     = (ENTRIES > 32) ? (ENTRIES % SEC_ENTRY) : 0;
localparam      PAD_ENTRY   = SECTIONS * SEC_ENTRY;

// Calculate the number of M9Ks required.
localparam      M9Ks        = SECTIONS * SLICES;

// I/O Section
input                   reset;
input                   wr_clk, wr_en;
input   [KEY-1:0]       wr_key;
input   [INDEX-1:0]     wr_index;
input                   wr_erase_n;
input                   rd_clk, rd_en;
input   [KEY-1:0]       rd_key;

output  [ENTRIES-1:0]   one_hot_addr;
output  [INDEX-1:0]     match_addr;
output                  match, multi_match;
output  [PAD_ENTRY-1:0] index_reg;
output                  cam_full, multi_index;

genvar  i, j;

integer x, y, z;

reg     [PAD_ENTRY-1:0] bin_addr_reg;
reg                     reg_wr_erase_n;
reg     [INDEX-1:0]     reg_wr_index;
reg                     rd_en_reg1, rd_en_reg2;

wire                    multi_match;
wire                    pre_match;
wire                    match;

// Type 'logic' in System Verilog
reg     [PAD_ENTRY-1:0] bin_addr;
reg     [SECTIONS-1:0]  wr_en_section;

wire    [SEC_KEY-1:0]   key_addr_slice [SLICES-1:0];
wire    [SEC_ENTRY-1:0] rd_addr_slice [SLICES-1:0][SECTIONS-1:0];

wire    [(SEC_KEY-KEY_MOD)-1:0] extra_zeros = 0;

assign  one_hot_addr = bin_addr_reg[ENTRIES-1:0];

// 
// synthesis translate_off
//
// In simulation, print out the parameters.
initial
    begin
        $display("  ==> # of ENTRIES = %0d", ENTRIES);
        $display("  ==> # of KEY = %0d", KEY);
        $display("  ==> # of INDEX = %0d", INDEX);
        $display("  ==> # of SECTIONS = %0d", SECTIONS);
        $display("  ==> # of SLICES = %0d", SLICES);
        $display("  ==> # of SEC_KEY = %0d", SEC_KEY);
        $display("  ==> # of KEY_MOD = %0d", KEY_MOD);
        $display("  ==> # of SEC_ENTRY = %0d", SEC_ENTRY);
        $display("  ==> # of SEC_INDEX = %0d", SEC_INDEX);
        $display("  ==> # of SEC_ADDR = %0d", SEC_ADDR);
        $display("  ==> # of SEC_MOD = %0d", SEC_MOD);
        $display("  ==> # of PAD_ENTRY = %0d", PAD_ENTRY);
        $display("  ==> # of M9Ks = %0d", M9Ks);
    end
// 
// synthesis translate_on
//
    
generate
    if (SECTIONS > 1)
    begin
        always @(posedge wr_clk)
            begin
                for (x=0; x<SECTIONS; x=x+1)
                begin
                    wr_en_section[x] <= wr_en & (wr_index[INDEX-1:SEC_INDEX] == x);
                end
            end
    end
    else
    begin
        always @(posedge wr_clk)
        begin
            wr_en_section    <= wr_en;
        end
    end
endgenerate

generate
    always @(*)
    begin
        for (x=0; x<SECTIONS; x=x+1)
        begin
            for (y=0; y<SEC_ENTRY; y=y+1)
            begin
                if ((x == (SECTIONS-1)) && (SEC_MOD != 0) && (y >= SEC_MOD))
                begin
                    bin_addr[(x*SEC_ENTRY)+y] = 1'b0;
                end
                else
                begin
                    bin_addr[(x*SEC_ENTRY)+y] = 1'b1;
                    for (z=0; z<SLICES; z=z+1)
                    begin
                        bin_addr[(x*SEC_ENTRY)+y] = bin_addr[(x*SEC_ENTRY)+y] & rd_addr_slice[z][x][y];
                    end
                end
            end
        end
    end
endgenerate

always @(posedge rd_clk or posedge reset)
begin
    if (reset)
        bin_addr_reg        <= 0;
    else
        bin_addr_reg        <= bin_addr;
end

always @(posedge wr_clk or posedge reset)
begin
    if (reset)
    begin
        reg_wr_erase_n      <= 1'b0;
        reg_wr_index        <= {INDEX{1'b0}};
    end
    else
    begin
        reg_wr_erase_n      <= wr_erase_n;
        reg_wr_index        <= wr_index;
    end
end

//
// Instantiations
//

// Stored Key Slices
generate
    for (i=0; i<SLICES; i=i+1)
    begin: stored_keys_slice
        if (i == 0)
            erase_keys #(
                .FAMILY     ( FAMILY ),
                .S_KEY      ( SEC_KEY ),
                .ENTRIES    ( ENTRIES )
                ) erase_keys_inst (
                .reset      ( reset ),
                .wr_clk     ( wr_clk ),
                .wr_en      ( wr_en ),
                .wr_key     ( wr_key[SEC_KEY-1:0] ),
                .wr_index   ( wr_index ),
                .wr_erase_n ( wr_erase_n ),
                .key_addr   ( key_addr_slice[0] ),
                .index_reg  ( index_reg ),
                .cam_full   ( cam_full ),
                .multi_index( multi_index)
                );
        else if ((i == (SLICES-1)) && (KEY_MOD != 0))
            erase_keys #(
                .FAMILY     ( FAMILY ),
                .S_KEY      ( SEC_KEY ),
                .ENTRIES    ( ENTRIES )
                ) erase_keys_inst (
                .reset      ( reset ),
                .wr_clk     ( wr_clk ),
                .wr_en      ( wr_en ),
                .wr_key     ( {extra_zeros, wr_key[(i*SEC_KEY)+KEY_MOD-1:i*SEC_KEY]} ),
                .wr_index   ( wr_index ),
                .wr_erase_n ( wr_erase_n ),
                .key_addr   ( key_addr_slice[i] ),
                .index_reg  (  ),
                .cam_full   (  ),
                .multi_index(  )
                );
        else
            erase_keys #(
                .FAMILY     ( FAMILY ),
                .S_KEY      ( SEC_KEY ),
                .ENTRIES    ( ENTRIES )
                ) erase_keys_inst (
                .reset      ( reset ),
                .wr_clk     ( wr_clk ),
                .wr_en      ( wr_en ),
                .wr_key     ( wr_key[(i*SEC_KEY)+SEC_KEY-1:i*SEC_KEY] ),
                .wr_index   ( wr_index ),
                .wr_erase_n ( wr_erase_n ),
                .key_addr   ( key_addr_slice[i] ),
                .index_reg  (  ),
                .cam_full   (  ),
                .multi_index(  )
                );
    end
endgenerate

// CAM Sections and Slices
generate
    for (i=0; i<SLICES; i=i+1)
    begin: cam_slice
        if ((i == (SLICES-1)) && (KEY_MOD != 0))
            for (j=0; j<SECTIONS; j=j+1)
            begin: cam_section
                dpram #(
                    .FAMILY     ( FAMILY ),
                    .S_KEY      ( SEC_KEY ),
                    .S_ENTRIES  ( SEC_ENTRY )
                    ) dpram_inst (
                    .data       ( reg_wr_erase_n ),
                    .rdaddress  ( {extra_zeros, wr_key[(i*SEC_KEY)+KEY_MOD-1:i*SEC_KEY]} ),
                    .rdclock    ( rd_clk ),
                    .rden       ( rd_en ),
                    .wraddress  ( {key_addr_slice[i], reg_wr_index[SEC_INDEX-1:0]} ),
                    .wrclock    ( wr_clk ),
                    .wren       ( wr_en_section[j] ),
                    .q          ( rd_addr_slice[i][j] )
                    );
            end
        else
            for (j=0; j<SECTIONS; j=j+1)
            begin: cam_section
                dpram #(
                    .FAMILY     ( FAMILY ),
                    .S_KEY      ( SEC_KEY ),
                    .S_ENTRIES  ( SEC_ENTRY )
                    ) dpram_inst (
                    .data       ( reg_wr_erase_n ),
                    .rdaddress  ( rd_key[(i*SEC_KEY)+SEC_KEY-1:i*SEC_KEY] ),
                    .rdclock    ( rd_clk ),
                    .rden       ( rd_en ),
                    .wraddress  ( {key_addr_slice[i], reg_wr_index[SEC_INDEX-1:0]} ),
                    .wrclock    ( wr_clk ),
                    .wren       ( wr_en_section[j] ),
                    .q          ( rd_addr_slice[i][j] )
                    );
            end
    end
endgenerate

`ifdef ENCODED_OUT
    // CAM Address Encoder
    prior_enc #(
        .WIDTH      ( PAD_ENTRY )
        ) prior_enc_inst (
        .data_in    ( bin_addr_reg ),
        .encode_out ( match_addr ),
        .enable_out ( pre_match )
        );
`else
    wire [INDEX-1:0]    match_addr = {INDEX{'b0}};
    wire                pre_match = |{bin_addr_reg};
`endif

always @(posedge rd_clk or posedge reset)
begin
    if (reset)
    begin
        rd_en_reg2  <= 1'b0;
        rd_en_reg1  <= 1'b0;
    end
    else
    begin
        rd_en_reg2  <= rd_en_reg1;
        rd_en_reg1  <= rd_en;
    end
end

assign  match = rd_en_reg2 && pre_match;

`ifdef MULTI_MATCH_OUT
    // CAM Multiple Key Match Checker
    multi_bit_check #(
        .WIDTH      ( PAD_ENTRY )
        ) multi_bit_check_inst (
        .data_in    ( bin_addr_reg ),
        .multi_bit  ( multi_match )
        );
`else
    assign  multi_match = 0;
`endif

function integer log2;
input [31:0] bits;
integer k;
begin
    log2 = 1;
    for (k=0; 2**k < bits; k=k+1)
        log2 = k + 1;
end
endfunction     // log2

function integer ceil;
input [31:0] n;
input [31:0] d;
begin
    ceil = (n + (d - 1)) / d;
end
endfunction     // ceil
parameter WAIT1 = 0, WAIT2 = 1,WAIT3 = 2;
reg [1:0] next_state,state;
reg busy_reg,busy_next;
reg move_state,move;
wire busy;

always@(wr_key,wr_index,move)begin
		next_state = state;
		busy_next = busy_reg;
		move_state = move;
		case (state)
			WAIT1 : begin
					busy_next = 1'b0;
					next_state = WAIT2;
					move_state = 1'b0;
				end
			WAIT2 : begin
					busy_next = 1'b1;
					next_state = WAIT3;
					move_state = ~move;
				end
			WAIT3 : begin
					busy_next = 1'b1;
					next_state = WAIT1;
					move_state = ~move;
				end	
			default: begin
					busy_next = 1'b0;
					next_state = WAIT1;
				end	
		endcase		
end


always @(posedge wr_clk) begin
		if (reset) 
			state <= WAIT1;
		else begin
			state <= next_state;	
			busy_reg <= busy_next;
			move <= move_state;
		end
	end
	
assign busy = 	busy_reg;
endmodule       // cam
