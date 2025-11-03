module ex_mem_reg(
input wire
	i_clk //Clock
	i_rst //Reset
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

output reg [31:0] o_ex_out, o_new_pc,
output reg [4:0] o_rd,
output reg
	//Memory Signals
	o_mem_read,
	o_mem_write,
	o_is_word,
	o_is_h_or_b,
	o_is_unsigned_ld,
	//Write Back Signals
//	i_is_lui,
//	i_is_auipc,
//	i_jump,
//	i_branch,
	o_reg_write,
);

d_ff #(WIDTH = 1) mem_read_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_mem_read), .q(o_mem_read));
d_ff #(WIDTH = 1) mem_write_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_mem_write), .q(o_mem_write));
d_ff #(WIDTH = 1) is_word_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_is_word), .q(o_is_word));
d_ff #(WIDTH = 1) is_h_or_b_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_is_h_or_b), .q(o_is_h_or_b));
d_ff #(WIDTH = 1) is_unsigned_ld_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_is_unsigned_ld), .q(o_is_unsigned_ld));
d_ff #(WIDTH = 1) reg_write_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_reg_write), .q(o_reg_write));

d_ff #(WIDTH = 32) ex_out_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_ex_out), .q(o_ex_out));
d_ff #(WIDTH = 32) new_pc_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_new_pc), .q(o_new_pc));

d_ff #(WIDTH = 5) new_pc_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_rd), .q(o_rd));
endmodule
