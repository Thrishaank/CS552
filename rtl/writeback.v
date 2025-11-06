module writeback(
    input i_clk, i_rst,
    input mem_read, reg_write,
    input [31:0] mem_data_out, ex_data_out,
    output [31:0] reg_write_data,
    output reg_write_en
);
    // TODO: remove LUI and AUIPC from mux, will just get from execute output

    assign reg_write_data = mem_read ? mem_data_out : ex_data_out;
    assign reg_write_en = reg_write;

    /* KEPT IF NEEDED IN FUTURE
    assign reg_write_data = jump
        ? pc_plus4 // jal or jalr
        : (is_lui)
            ? imm // lui
            : is_auipc 
                ? pc + imm  // auipc
                : mem_read 
                    ? mem_data_out // load
                    : ex_data_out; // All other instructions
    */

endmodule