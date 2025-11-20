module writeback(
    input i_clk, i_rst,
    input mem_read,
    input [31:0] mem_data_out, ex_data_out,
    output [31:0] reg_write_data
);
    // TODO: remove LUI and AUIPC from mux, will just get from execute output

    assign reg_write_data = mem_read ? mem_data_out : ex_data_out;

    input [31:0] i_dmem_rdata, ex_data_out,
    input is_word, is_h_or_b, is_unsigned_ld,
    output [31:0] reg_write_data, mem_data_out
);

    wire [1:0] address_l2b = ex_data_out[1:0];
    // TODO: remove LUI and AUIPC from mux, will just get from execute output

    assign reg_write_data = mem_read ? mem_data_out : ex_data_out;

    // Assign mem_data_out based on load type and address alignment
    assign mem_data_out = is_word
        ? i_dmem_rdata // If word
        : is_h_or_b
            ? address_l2b[1] // If half-word
                ? is_unsigned_ld
                    ? {16'b0, i_dmem_rdata[31:16]} // Unsigned half-word upper
                    : {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]} // Signed half-word upper
                : is_unsigned_ld
                    ? {16'b0, i_dmem_rdata[15:0]} // Unsigned half-word lower
                    : {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]} // Signed half-word lower
            : address_l2b[1:0] == 2'b00 // If byte
                ? is_unsigned_ld
                    ? {24'b0, i_dmem_rdata[7:0]} // Unsigned byte 1st
                    : {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]} // Signed byte 1st
                : address_l2b[1:0] == 2'b01
                    ? is_unsigned_ld
                        ? {24'b0, i_dmem_rdata[15:8]} // Unsigned byte 2nd
                        : {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]} // Signed byte 2nd
                    : address_l2b[1:0] == 2'b10
                        ? is_unsigned_ld
                            ? {24'b0, i_dmem_rdata[23:16]} // Unsigned byte 3rd
                            : {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]} // Signed byte 3rd
                        : is_unsigned_ld
                            ? {24'b0, i_dmem_rdata[31:24]} // Unsigned byte 4th
                            : {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]}; // Signed byte 4th
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