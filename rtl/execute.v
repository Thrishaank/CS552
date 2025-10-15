module execute (
    input clk, i_rst,
    input [31:0] pc, pc_plus4,
    input branch, memRead, memWrite, reg_write, imm_alu, i_arith, i_unsigned, i_sub, check_lt_or_eq, branch_expect_n, jump, reg_jump,
    input [2:0] i_opsel,
    input [31:0] reg_out_1, reg_out_2, imm,
    output [31:0] new_pc, alu_result
);
    wire eq, lt;

    wire [31:0] result;

    wire pc_plus_offset;

    assign pc_plus_offset = (jump | (branch & ((check_lt_or_eq) ? 
                        (branch_expect_n ^ lt) : (branch_expect_n ^ eq)))) ? 
                    (pc + imm) : (pc_plus4);

    assign new_pc = (reg_jump) ? {alu_result[31:1], 1'b0} : pc_plus_offset;

    //TODO: Implement rest of ALU logic here

    
endmodule