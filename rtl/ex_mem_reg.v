module ex_mem_reg(
	input wire
		i_clk, //Clock
		i_rst, //Reset

	// Memory control signals
	input wire i_mem_read, i_mem_write, i_is_word, i_is_h_or_b, i_is_unsigned_ld, i_reg_write_en,
	output wire o_mem_read, o_mem_write, o_is_word, o_is_h_or_b, o_is_unsigned_ld, o_reg_write_en,

	input wire [31:0] i_pc, i_new_pc,
	input wire [31:0] i_ex_data_out,
	input wire [31:0] i_reg_out_1, i_reg_out_2,
	input wire [4:0] i_rs1_addr, i_rs2_addr, i_rd_addr,
	input wire i_rs1_used, i_rs2_used,
	input wire i_halt, i_valid,
	input wire [31:0] i_instruction,

	output wire [31:0] o_pc, o_new_pc,
	output wire [31:0] o_ex_data_out,
	output wire [31:0] o_reg_out_1, o_reg_out_2,
	output wire [4:0] o_rs1_addr, o_rs2_addr, o_rd_addr,
	output wire o_rs1_used, o_rs2_used,
	output wire o_halt, o_valid,
	output wire [31:0] o_instruction
);

	// NOP instruction (addi x0, x0, 0) = 32'h00000013
	localparam [31:0] NOP = 32'h00000013;

	d_ff mem_read_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_mem_read), .q(o_mem_read));
	d_ff mem_write_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_mem_write), .q(o_mem_write));
	d_ff is_word_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_is_word), .q(o_is_word));
	d_ff is_h_or_b_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_is_h_or_b), .q(o_is_h_or_b));
	d_ff is_unsigned_ld_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_is_unsigned_ld), .q(o_is_unsigned_ld));
	d_ff reg_write_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_reg_write_en), .q(o_reg_write_en));

	d_ff #(.WIDTH(32)) new_pc_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_new_pc), .q(o_new_pc));
	d_ff #(.WIDTH(32)) pc_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_pc), .q(o_pc));

	d_ff #(.WIDTH(32)) ex_data_out_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_ex_data_out), .q(o_ex_data_out));
	d_ff #(.WIDTH(32)) reg_out_1_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_reg_out_1), .q(o_reg_out_1));
	d_ff #(.WIDTH(32)) reg_out_2_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_reg_out_2), .q(o_reg_out_2));

	d_ff #(.WIDTH(32), .RST_VAL(NOP)) instruction_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_instruction), .q(o_instruction));

	d_ff rs1_used_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_rs1_used), .q(o_rs1_used));
	d_ff rs2_used_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_rs2_used), .q(o_rs2_used));

	d_ff halt_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_halt), .q(o_halt));
	d_ff valid_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_valid), .q(o_valid));

	d_ff #(.WIDTH(5)) rs1_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_rs1_addr), .q(o_rs1_addr));
	d_ff #(.WIDTH(5)) rs2_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_rs2_addr), .q(o_rs2_addr));
	d_ff #(.WIDTH(5)) rd_dff(.i_rst(i_rst), .i_clk(i_clk), .d(i_rd_addr), .q(o_rd_addr));

endmodule