module mem_wb_reg(
    input i_clk, i_rst, i_stall,
    // Inputs
    input i_mem_read, i_reg_write,
    input [31:0] i_mem_data_out, i_alu_result,
    // Outputs
    output o_em_read, o_reg_write,
    output [31:0] o_mem_data_out, o_alu_result,
);

wire [31:0] NOP = 32'h00000013;

d_ff mem_read_ff (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .d(i_stall ? o_mem_read : i_mem_read),
    .q(o_mem_read)
);

d_ff reg_write_ff (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .d(i_stall ? o_reg_write : i_reg_write),
    .q(o_reg_write)
);

d_ff #(.WIDTH(32), .RST_VAL(NOP)) mem_data_out_ff (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .d(i_stall ? o_mem_data_out : i_mem_data_out),
    .q(o_mem_data_out)
);

d_ff #(.WIDTH(32), .RST_VAL(NOP)) alu_result_ff (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .d(i_stall ? o_alu_result : i_alu_result),
    .q(o_alu_result)
);

endmodule