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
 * Module Name: decoder                 File Name: decoder.v                   *
 *                                                                             *
 * Module Function: This module implements a decoder.  The binary              *
 *                  encoded input will be decoded to its corresponding         *
 *                  2**N-bit one-hot output.                                   *
 *                                                                             *
 * Modules Used:                                                               *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *      - N             : Number of bits of input data                         *
 *      - WIDTH         : Width of output data                                 *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 08/06/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      08/06/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *                                                                             *
 ******************************************************************************/

module decoder (
                encode_in,
                data_out
                );

parameter   WIDTH       = 64;
parameter   N           = log2(WIDTH);

input   [N-1:0]         encode_in;
output  [WIDTH-1:0]     data_out;

reg     [WIDTH-1:0]     data_out;
//reg       [N-1:0]         position;

integer i;

always @(*)
begin
    data_out = 0;
    data_out = data_out + 2**(encode_in);
end

function integer log2;
input [32:0] depth;
integer j;
begin
    log2 = 1;
    for (j=0; 2**j < depth; j=j+1)
        log2 = j + 1;
end
endfunction     // log2

endmodule       // decoder
