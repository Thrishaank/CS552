module decode(
    input clk, i_rst,
    input [31:0] instruction,
    input [31:0] reg_write_data,
    input [31:0] pc_plus4,
    output branch, mem_read, mem_write, regWrite, immALU, check_lt_or_eq, branch_expect_n, jump, reg_jump, is_word, is_h_or_b, is_unsigned_ld, 
    output i_arith, i_unsigned, i_sub,
    output [2:0] i_opsel,
    output [31:0] reg_out_1, reg_out_2, imm_out
);
    assign check_lt_or_eq = instruction[14];
    assign branch_expect_n = instruction[12];

endmodule