module writeback(
    input i_clk, i_rst,
    input mem_read, reg_write, is_auipc, is_lui, jump,
    input [31:0] mem_data_out, alu_result, pc, pc_plus4, imm,
    output [31:0] reg_write_data,
    output reg_write_en
);
    // TODO: remove LUI and AUIPC from mux, will just get from execute output //DONE
    //TODO: EXECUTE OUTPUT TO BE LINKED TO HERE FOR JUMP ADDRESS 

    assign reg_write_data = jump
        ? pc_plus4      // jal or jalr - return address
        : mem_read 
            ? mem_data_out  // load instruction
            : alu_result;   // All other instructions (including LUI, AUIPC)

    // Will be useful when pipelining
    assign reg_write_en = reg_write;

endmodule