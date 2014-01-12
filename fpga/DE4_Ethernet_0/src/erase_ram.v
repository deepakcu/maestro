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
 * Module Name: erase_ram               File Name: erase_ram.v                 *
 *                                                                             *
 * Module Function: This module implements the SP RAM for storing keys the     *
 *                  basic CAM section.  When storing a key location, the key   *
 *                  is written into the Erase RAM so that it can be erased     *
 *                  at a later time.                                           *
 *                                                                             *
 * Modules Used:                                                               *
 *          altsyncram      Stratix IV Memory ATOM                             *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *          FAMILY              Cyclone III/IV, or Stratix III/IV              *
 *          S_KEY           Section KEY                                        *
 *          ENTRIES         Total Entries in CAM                               *
 *          INDEX           log 2 (ENTRIES)                                    *
 *          CEIL_ENTRY      2**INDEX                                           *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 10/05/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      10/05/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *                                                                             *
 ******************************************************************************/

module erase_ram (
                address,
                clock,
                data,
                wren,
                q
                );

// Target FPGA Family
parameter   FAMILY      = "Stratix IV";

// Section KEY
parameter   S_KEY       = 8;                // Default (8)

// CAM ENTRIES
parameter   ENTRIES     = 416;              
localparam  INDEX       = log2(ENTRIES);    // Default (9)
localparam  CEIL_ENTRY  = 2**INDEX;         // Default (512)

input   [INDEX-1:0] address;
input               clock;
input   [S_KEY-1:0] data;
input               wren;
output  [S_KEY-1:0] q;

`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1      clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

wire    [S_KEY-1:0] sub_wire0;
wire    [S_KEY-1:0] q = sub_wire0;

    altsyncram  altsyncram_component (
                .wren_a         ( wren ),
                .clock0         ( clock ),
                .address_a      ( address ),
                .data_a         ( data ),
                .q_a            ( sub_wire0 ),
                .aclr0          ( 1'b0 ),
                .aclr1          ( 1'b0 ),
                .address_b      ( 1'b1 ),
                .addressstall_a ( 1'b0 ),
                .addressstall_b ( 1'b0 ),
                .byteena_a      ( 1'b1 ),
                .byteena_b      ( 1'b1 ),
                .clock1         ( 1'b1 ),
                .clocken0       ( 1'b1 ),
                .clocken1       ( 1'b1 ),
                .clocken2       ( 1'b1 ),
                .clocken3       ( 1'b1 ),
                .data_b         ( 1'b1 ),
                .eccstatus      ( ),
                .q_b            ( ),
                .rden_a         ( 1'b1 ),
                .rden_b         ( 1'b1 ),
                .wren_b         ( 1'b0 )
                );
defparam
        altsyncram_component.clock_enable_input_a           = "BYPASS",
        altsyncram_component.clock_enable_output_a          = "BYPASS",
        `ifdef NO_PLI
            altsyncram_component.init_file                      = "erase_ram.rif"
        `else
            altsyncram_component.init_file                      = "erase_ram.hex"
        `endif
        ,
        altsyncram_component.intended_device_family         = FAMILY,
        altsyncram_component.lpm_type                       = "altsyncram",
        altsyncram_component.numwords_a                     = CEIL_ENTRY,
        altsyncram_component.operation_mode                 = "SINGLE_PORT",
        altsyncram_component.outdata_aclr_a                 = "NONE",
        altsyncram_component.outdata_reg_a                  = "UNREGISTERED",
        altsyncram_component.power_up_uninitialized         = "FALSE",
        altsyncram_component.ram_block_type                 = "MLAB",
        altsyncram_component.read_during_write_mode_port_a  = "DONT_CARE",
        altsyncram_component.widthad_a                      = INDEX,
        altsyncram_component.width_a                        = S_KEY,
        altsyncram_component.width_byteena_a                = 1;

function integer log2;
input [32:0] bits;
integer k;
begin
    log2 = 1;
    for (k=0; 2**k < bits; k=k+1)
        log2 = k + 1;
end
endfunction     // log2

endmodule       // erase_ram
