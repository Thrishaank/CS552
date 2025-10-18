module decode(
    input clk, i_rst,
    input [31:0] instruction,
    input [31:0] reg_write_data,
    input [31:0] pc_plus4,
    input reg_write_en,
    output branch, immALU, check_lt_or_eq, branch_expect_n, jump, reg_jump, 
    output i_arith, i_unsigned, i_sub,
    output [2:0] i_opsel,
    output is_auipc, is_lui,
    output [4:0] rs1_addr, rs2_addr, rd_addr,
    output [31:0] reg_out_1, reg_out_2, imm_out,
    output mem_read, mem_write, is_word, is_h_or_b, is_unsigned_ld,
    output reg_write
);
    assign check_lt_or_eq = instruction[14];
    assign branch_expect_n = instruction[12];

endmodule