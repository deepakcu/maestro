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
 * Module Name: dpram                   File Name: dpram.v                     *
 *                                                                             *
 * Module Function: This module implements the DP RAM for the basic CAM        *
 *                  section.  Port A is ROW x 1, Port B is DEPTH x ENTRIES     *
 *                  The CAM is specified as ENTRIES x KEY.  This is for        *
 *                  Cyclone/Stratix III/IV Families.                           *
 *                                                                             *
 * Modules Used:                                                               *
 *          altsyncram      Memory ATOM                                        *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *          FAMILY          Cyclone III, Stratix III, Cyclone IV, or Stratix IV*
 *          S_KEY           2**KEY = DEPTH                                     *
 *          S_ENTRIES       Width of Port B of DP RAM                          *
 *                                                                             *
 *      (Local)                                                                *
 *          S_DEPTH         Depth of Port B of DP RAM                          *
 *          S_INDEX         2**INDEX = ENTRIES                                 *
 *          S_ROWS          DEPTH * ENTRIES                                    *
 *          S_ROW_ADD       KEY + INDEX                                        *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 10/02/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      10/02/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *                                                                             *
 ******************************************************************************/

module dpram (
            data,
            rdaddress,
            rdclock,
            rden,
            wraddress,
            wrclock,
            wren,
            q
            );

parameter   FAMILY      = "Stratix IV";
// Section DEPTH of Port B can be from 16 to 4096
// (and Port A would then be from 32 to 8192 (8K))
parameter   S_KEY       = 8;
localparam  S_DEPTH     = 2**S_KEY;                 // Default (256)

// Section WIDTH of Port B can be from 2 to 256
// (and Port A will always be 1)
parameter   S_ENTRIES   = 32;                       // Also WIDTH
localparam  S_INDEX     = log2(S_ENTRIES);          // Default (5)
localparam  ADJ_ENTRY   = 2**S_INDEX;

// In order to fit in a M9K, S_KEY + S_INDEX <= 13 (or S_DEPTH x S_WIDTH <= 8K)
localparam  S_ROWS      = S_DEPTH * ADJ_ENTRY;   // Default (8192)
localparam  S_ROW_ADDR  = S_KEY + S_INDEX;          // Default (13)

input                   data;
input   [S_KEY-1:0]     rdaddress;
input                   rdclock;
input                   rden;
input   [S_ROW_ADDR-1:0]wraddress;
input                   wrclock;
input                   wren;
output  [ADJ_ENTRY-1:0] q;

`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1                    rden;
    tri1                    wrclock;
    tri0                    wren;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

wire [ADJ_ENTRY-1:0]    sub_wire0;
wire [ADJ_ENTRY-1:0]    q = sub_wire0;

altsyncram  altsyncram_component (
            .wren_a             ( wren ),
            .clock0             ( wrclock ),
            .clock1             ( rdclock ),
            .address_a          ( wraddress ),
            .address_b          ( rdaddress ),
            .rden_b             ( rden ),
            .data_a             ( data ),
            .q_b                ( sub_wire0 ),
            .aclr0              ( 1'b0 ),
            .aclr1              ( 1'b0 ),
            .addressstall_a     ( 1'b0 ),
            .addressstall_b     ( 1'b0 ),
            .byteena_a          ( 1'b1 ),
            .byteena_b          ( 1'b1 ),
            .clocken0           ( 1'b1 ),
            .clocken1           ( 1'b1 ),
            .clocken2           ( 1'b1 ),
            .clocken3           ( 1'b1 ),
            .data_b             ( {ADJ_ENTRY{1'b1}} ),
            .eccstatus          ( ),
            .q_a                ( ),
            .rden_a             ( 1'b1 ),
            .wren_b             ( 1'b0 )
            );
defparam
            altsyncram_component.address_aclr_b         = "NONE",
            altsyncram_component.address_reg_b          = "CLOCK1",
            altsyncram_component.clock_enable_input_a   = "BYPASS",
            altsyncram_component.clock_enable_input_b   = "BYPASS",
            altsyncram_component.clock_enable_output_b  = "BYPASS",
            `ifdef NO_PLI
                altsyncram_component.init_file          = "dpram.rif"
            `else
                altsyncram_component.init_file          = "dpram.hex"
            `endif
            ,
            altsyncram_component.init_file_layout       = "PORT_B",
            altsyncram_component.intended_device_family = FAMILY,
            altsyncram_component.lpm_type               = "altsyncram",
            altsyncram_component.numwords_a             = S_ROWS,
            altsyncram_component.numwords_b             = S_DEPTH,
            altsyncram_component.operation_mode         = "DUAL_PORT",
            altsyncram_component.outdata_aclr_b         = "NONE",
            altsyncram_component.outdata_reg_b          = "UNREGISTERED",
            altsyncram_component.power_up_uninitialized = "FALSE",
            altsyncram_component.ram_block_type         = "M9K",
            altsyncram_component.rdcontrol_reg_b        = "CLOCK1",
            altsyncram_component.widthad_a              = S_ROW_ADDR,
            altsyncram_component.widthad_b              = S_KEY,
            altsyncram_component.width_a                = 1,
            altsyncram_component.width_b                = ADJ_ENTRY,
            altsyncram_component.width_byteena_a        = 1;

function integer log2;
input [31:0] bits;
integer k;
begin
    log2 = 1;
    for (k=0; 2**k < bits; k=k+1)
        log2 = k + 1;
end
endfunction     // log2

endmodule       // dpram
