

/*checksum available 6 cycles after all inputs asserted*/
module binary_adder_tree(A, B, C, D, E, F, G, H, I, clk, checksum_reg);
   
	input	[15:0] A, B, C, D, E, F, G, H, I;
	input	clk;
	output	reg [15:0] checksum_reg;

	wire    [15:0]    checksum;
	wire	[16:0]    sum_a_b, sum_c_d, sum_e_f, sum_g_h, sum_ab_cd, sum_ef_gh, sum_abcd_efgh, sum_i;
	reg	[16:0]    sumreg_ab, sumreg_cd, sumreg_ef, sumreg_gh, sumreg_ab_cd, sumreg_ef_gh, sumreg_abcd_efgh, sumreg_i;
	// Registers
	always @ (posedge clk)
		begin
			//cycle 1
			sumreg_ab <= sum_a_b;
			sumreg_cd <= sum_c_d;
			sumreg_ef <= sum_e_f;
			sumreg_gh <= sum_g_h;

			//cycle 2
			sumreg_ab_cd <= sum_ab_cd;
			sumreg_ef_gh <= sum_ef_gh;
			
			//cycle 3
			sumreg_abcd_efgh <= sum_abcd_efgh;

			//cycle 4
			sumreg_i <= sum_i;

			//CYCLE 5
			checksum_reg <= checksum;
		end
	// 2-bit additions
	assign 			  sum_a_b = A + B;
	assign 			  sum_c_d = C + D;
	assign			  sum_e_f = E + F;
	assign 			  sum_g_h = G + H;

	assign 			  sum_ab_cd = sumreg_ab + sumreg_cd;
	assign 			  sum_ef_gh = sumreg_ef + sumreg_gh;

	assign 			  sum_abcd_efgh = sumreg_ab_cd + sumreg_ef_gh;
	assign			  sum_i = sumreg_abcd_efgh+I;
	
	assign 			  checksum = ~((sumreg_i[16]==1'b1)?(sumreg_i[15:0]+1):sumreg_i[15:0]);
endmodule
