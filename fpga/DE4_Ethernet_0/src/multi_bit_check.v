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
 * Module Name: multi_bit_check         File Name: multi_bit_check.v           *
 *                                                                             *
 * Module Function: This module checks to see if more than one bit is set in   *
 *                  an input bus.                                              *
 *                                                                             *
 * Modules Used:                                                               *
 *                                                                             *
 * Parameters and Defines Used:                                                *
 *      - N             : Power for number of bits of input data               *
 *      - WIDTH         : Width of input data                                  *
 *                                                                             *
 * Created by:  Jim Schwalbe            Created on: 08/06/2009                 *
 *                                                                             *
 * REVISION HISTORY:                                                           *
 *  * Revision 1.0      08/06/2009      Jim Schwalbe                           *
 *      - Initial Revision                                                     *
 *                                                                             *
 ******************************************************************************/

module multi_bit_check (
                data_in,
                multi_bit
                );

parameter   WIDTH       = 64;
parameter   N           = log2(WIDTH);

input   [WIDTH-1:0]     data_in;
output                  multi_bit;

reg     [N-1:0]         sum;
reg                     multi_bit;

integer j;

always @(*)
begin
    multi_bit  = 0;
    sum = 0;
    for (j=WIDTH-1; j >= 0; j = j-1)
        sum = sum + data_in[j];
    if (sum > 1)
        multi_bit = 1;
end

function integer log2;
input [32:0] depth;
integer i;
begin
    log2 = 1;
    for (i=0; 2**i < depth; i=i+1)
        log2 = i + 1;
end
endfunction     // log2

endmodule       // multi_bit_check
