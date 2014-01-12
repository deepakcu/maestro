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
 * Module Name: prior_enc               File Name: prior_enc.v                 *
 *                                                                             *
 * Module Function: This module implements a priority encoder.  The binary     *
 *                  encoded output will indicate the highest bit set in the    *
 *                  input data.                                                *
 *                                                                             *
 * Modules Used:                                                               *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *      - N             : Number of bits of output data                        *
 *      - WIDTH         : Width of input data                                  *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 08/06/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      08/06/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *                                                                             *
 ******************************************************************************/

module prior_enc (
                data_in,
                encode_out,
                enable_out
                );

parameter   WIDTH       = 64;
parameter   N           = log2(WIDTH);

input   [WIDTH-1:0]     data_in;
output  [N-1:0]         encode_out;
output                  enable_out;

reg     [N-1:0]         encode_out;
reg                     enable_out;

reg     [N-1:0]         x;

integer i, j;

always @(*)
begin
    j = 0;
    for (i=0; i < WIDTH; i=i+1)
        if (data_in[i] == 1'b1)
            j = i;
            
    encode_out  = j;
    enable_out  = |{data_in};
end

function integer log2;
input [31:0] depth;
integer k;
begin
    log2 = 1;
    for (k=0; 2**k < depth; k=k+1)
        log2 = k + 1;
end
endfunction     // log2

endmodule       // prior_enc
