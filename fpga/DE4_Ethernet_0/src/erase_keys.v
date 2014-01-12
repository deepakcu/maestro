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
 * Module Name: erase_keys              File Name: erase_keys.v                *
 *                                                                             *
 * Module Function: This module implements the control mechanism for deter-    *
 *                  mining which key to erase when removing keys.  There are   *
 *                  4 possible modes that can be used:                         *
 *                  MODE 1: Full External - All control is external to CAM.    *
 *                  MODE 2: Random Internal - Keys stored internal with        *
 *                          external control of index for random selection.    *
 *                  MODE 3: FIFO Internal - Keys stored internal in FIFO with  *
 *                          external control of index when storing.            *
 *                  MODE 4: FIFO Auto - Keys stored internal in FIFO with      *
 *                          automatic sequential index.                        *
 *                                                                             *
 * Modules Used:                                                               *
 *          erase_ram       For storing keys                                   *
 *          decoder         For decoding upper index bits (for Sections)       *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *          FULL_EXTERNAL   Fully external control of random key erasure       *
 *          RANDOM_INTERNAL Internal control of random key erasure             *
 *          FIFO_INTERNAL   Internal control of FIFO key erasure (TBD)         *
 *          FIFO_AUTO       Fully automated FIFO key erasure (TBD)             *
 *          FAMILY          Cyclone III/IV, or Stratix III/IV                  *
 *          S_KEY           Section KEY                                        *
 *          ENTRIES         Total Entries in CAM                               *
 *                                                                             *
 *      (Local)                                                                *
 *          INDEX           log 2 (ENTRIES)                                    *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 10/05/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      10/05/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *  * Revision 1.1      10/20/2010      Jim Schwalbe                           *
 *      - Added latch to erase_keys since data from Erase RAM changes on       *
 *        falling edge of wr_clk for generation of key_addr.                                              *
 *      - Added pipeline register to wr_key and wr_erase_n for generation of   *
 *        key_addr.
 *                                                                             *
 ******************************************************************************/

module erase_keys (
                reset,
                wr_clk,
                wr_en,
                wr_key,
                wr_index,
                wr_erase_n,
                key_addr,
                index_reg,
                cam_full,
                multi_index
                );
                
// Configuration of erase key management; select (uncomment) only one
//`define     FULL_EXTERNAL
`define     RANDOM_INTERNAL
//`define     FIFO_INTERNAL
//`define     FIFO_AUTO

// Target FPGA Family
parameter   FAMILY      = "Stratix IV";

// Section KEY
parameter   S_KEY       = 8;                // Default (8)

// CAM ENTRIES
parameter   ENTRIES     = 416;              
localparam  INDEX       = log2(ENTRIES);    // Default (9)
localparam  ADJ_ENTRY   = 2**INDEX;

input                   reset;
input                   wr_clk, wr_en;
input   [S_KEY-1:0]     wr_key;
input   [INDEX-1:0]     wr_index;
input                   wr_erase_n;

output  [S_KEY-1:0]     key_addr;
output  [ADJ_ENTRY-1:0] index_reg;
output                  cam_full, multi_index;

reg                     rst_reg1, rst_reg2;

// Synchronize reset to wr_clk
always @(posedge wr_clk or posedge reset)
begin
    if (reset)
    begin
        rst_reg2    <= 1'b1;
        rst_reg1    <= 1'b1;
    end
    else
    begin
        rst_reg2    <= rst_reg1;
        rst_reg1    <= 1'b0;
    end
end

wire  wr_rst    = rst_reg2;


`ifdef RANDOM_INTERNAL

    reg     [ADJ_ENTRY-1:0] index_reg;
    reg                     multi_index;
    reg     [S_KEY-1:0]     lat_erase_key;
    reg                     reg_wr_erase_n;
    reg     [S_KEY-1:0]     reg_wr_key;

    wire    [S_KEY-1:0]     erase_key;
    wire    [ADJ_ENTRY-1:0] wr_index_decode;

    wire    [S_KEY-1:0]     key_addr = reg_wr_erase_n ? reg_wr_key : lat_erase_key;
    wire                    cam_full = &index_reg;
    
    always @(posedge wr_clk or posedge wr_rst)
    begin
        if (wr_rst)
        begin: reset_keys
            index_reg       <= {ADJ_ENTRY{1'b0}};
            multi_index     <= 1'b0;
            reg_wr_erase_n  <= 1'b0;
            reg_wr_key      <= {S_KEY{1'b0}};
        end
        else if (wr_en && wr_erase_n)
        begin: write_key
            index_reg       <= index_reg | wr_index_decode;
            reg_wr_erase_n  <= wr_erase_n;
            reg_wr_key      <= wr_key;
            if ((index_reg & wr_index_decode) != 0)
                multi_index <= 1'b1;
            else
                multi_index <= 1'b0;
        end
        else if (wr_en && !wr_erase_n)
        begin: remove_key
            index_reg   <= index_reg & ~wr_index_decode;
            multi_index <= 1'b0;
            reg_wr_erase_n  <= wr_erase_n;
            reg_wr_key      <= wr_key;
        end
        else
        begin
            index_reg   <= index_reg;
            multi_index <= 1'b0;
            reg_wr_erase_n  <= reg_wr_erase_n;
            reg_wr_key      <= reg_wr_key;
        end
    end
    
    // Latch the erase_key because it changes on falling edge of wr_clk   
    always @(erase_key or wr_clk)
    begin
        if (wr_clk)
        begin
            lat_erase_key <= erase_key;
        end
    end
    
    //
    // Instantiations
    //

    // Erase Key Store
    erase_ram #(
        .FAMILY     ( FAMILY ),
        .S_KEY      ( S_KEY ),
        .ENTRIES    ( ADJ_ENTRY )
        ) erase_ram_inst (
        .address    ( wr_index ),
        .clock      ( wr_clk ),
        .data       ( wr_key ),
        .wren       ( wr_en ),
        .q          ( erase_key )
        );
        
    // Decoder for key
    decoder #(
        .WIDTH      ( ADJ_ENTRY )
        ) decoder_inst (
        .encode_in  ( wr_index ),
        .data_out   ( wr_index_decode )
        );

`else   `ifdef FIFO_INTERAL

        // Future enhancement

        `else   `ifdef FIFO_AUTO

                // Future enhancement
    
                `else  //`ifdef FULL_EXTERNAL

                    // These outputs are not used
                    wire    [ADJ_ENTRY-1:0] index_reg = ADJ_ENTRY'b0;
                    wire                    multi_index = 0;
                    wire                    cam_full = 0;

                    // Pass the key through
                    wire    [S_KEY-1:0]     key_addr = wr_key;
                    
                `endif
        `endif
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

endmodule       // erase_keys
