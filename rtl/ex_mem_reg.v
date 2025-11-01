module ex_mem_reg(
input wire
	i_clk //Clock
	i_rst //Reset
	i_en //Enable
input reg
	//Memory Signals
	i_mem_read,
	i_mem_write,
	i_is_word,
	i_is_h_or_b,
	i_is_unsigned_ld,
	//Write Back Signals
//	i_is_lui,
//	is_auipc,
//	i_jump,
//	i_branch,
	i_reg_write,
		
input wire [31:0] i_ex_out, i_new_pc,
inddput wire [4:0] i_rd,

output reg [31:0] o_alu_out, o_new_pc,
output reg [4:0] o_rd,
output reg
	//Memory Signals
	o_mem_read,
	o_mem_write,
	o_is_word,
	o_is_h_or_b,
	i_is_unsigned_ld,
	//Write Back Signals
//	i_is_lui,
//	i_is_auipc,
//	i_jump,
//	i_branch,
	i_reg_write,
);

endmodule
