module writeback(
    input i_clk, i_rst,
    input mem_read, reg_write, is_auipc, is_lui,
    input [31:0] mem_data_out, alu_result, pc, pc_plus4, imm,
    output [31:0] reg_write_data,
    output reg_write_en
);

    assign reg_write_data = (is_lui) ? imm : (is_auipc ? pc + imm : (mem_read ? mem_data_out : alu_result));

    // Will be useful when pipelining
    assign reg_write_en = reg_write;

endmodule