module execute (
    input i_clk, i_rst,
    input [31:0] pc, pc_plus4,
    input branch, imm_alu, i_arith, i_unsigned, i_sub, check_lt_or_eq, branch_expect_n, jump, reg_jump,
    input [2:0] i_opsel,
    input [31:0] reg_out_1, reg_out_2, imm,
    output [31:0] next_pc, alu_result,
    output pc_write_trap
);
    wire eq, lt;

    wire [31:0] result;

    wire [31:0] pc_plus_offset;

    assign pc_plus_offset = (jump | (branch & 
        ((check_lt_or_eq) ? (branch_expect_n ^ lt) : (branch_expect_n ^ eq)))) // Check if branch is successful
            ? pc + imm // jal or successful branch
            : pc_plus4; // unsuccessful branch or other instruction;

    assign next_pc = reg_jump
         ? {alu_result[31:1], 1'b0} // jalr
         : pc_plus_offset; // Anything else

    assign pc_write_trap = |next_pc[1:0];

    wire [31:0] i_op2; 
    assign i_op2 = imm_alu 
                    ? imm // Use immediate as 2nd operand for instructions which use it
                    : reg_out_2; // Select register as 2nd operand for all other instructions
    alu iALU1(.i_opsel(i_opsel), .i_sub(i_sub), .i_unsigned(i_unsigned), .i_arith(i_arith),
        .i_op1(reg_out_1), .i_op2(i_op2), .o_result(alu_result), .o_eq(eq), .o_slt(lt));
endmodule
