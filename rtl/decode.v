module decode(
    input clk, i_rst,
    input [31:0] instruction,
    output branch, memRead, memWrite, regWrite, immALU, i_arith, i_unsigned, i_sub,
    output [2:0] i_opsel,
    output [31:0] regOut1, regOut2, imm_out
);

endmodule