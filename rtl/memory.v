module store(
    input clk, i_rst,
    input [31:0] address, w_data,
    input mem_read, mem_write, is_word, is_h_or_b, is_unsigned_ld,
    input [31:0] i_dmem_rdata,
    output [31:0] o_dmem_addr,
    output [31:0] o_dmem_wdata,
    output [3:0] o_dmem_mask,
    output o_dmem_ren, o_dmem_wen,
    output [31:0] data_mem_out
);

// Assign outputs to be input to data memory from module inputs
assign o_dmem_addr  = {address[31:2], 2'b00}; // Word align address
assign o_dmem_wdata = w_data;
assign o_dmem_ren   = mem_read;
assign o_dmem_wen   = mem_write;

// Calculate mask based on lowest 2 bits of address
assign o_dmem_mask = is_word
    ? 4'b1111 // If word
    : is_h_or_b
        ? address[1] // If half-word
            ? 4'b1100
            : 4'b0011
        : address[1:0] == 2'b00 // If byte
            ? 4'b0001
            : address[1:0] == 2'b01
                ? 4'b0010
                : address[1:0] == 2'b10
                    ? 4'b0100
                    : 4'b1000;

// Assign data_mem_out based on load type and address alignment
assign data_mem_out = is_word
    ? i_dmem_rdata // If word
    : is_h_or_b
        ? address[1] // If half-word
            ? is_unsigned_ld
                ? {16'b0, i_dmem_rdata[31:16]} // Unsigned half-word upper
                : {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]} // Signed half-word upper
            : is_unsigned_ld
                ? {16'b0, i_dmem_rdata[15:0]} // Unsigned half-word lower
                : {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]} // Signed half-word lower
        : address[1:0] == 2'b00 // If byte
            ? is_unsigned_ld
                ? {24'b0, i_dmem_rdata[7:0]} // Unsigned byte 1st
                : {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]} // Signed byte 1st
            : address[1:0] == 2'b01
                ? is_unsigned_ld
                    ? {24'b0, i_dmem_rdata[15:8]} // Unsigned byte 2nd
                    : {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]} // Signed byte 2nd
                : address[1:0] == 2'b10
                    ? is_unsigned_ld
                        ? {24'b0, i_dmem_rdata[23:16]} // Unsigned byte 3rd
                        : {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]} // Signed byte 3rd
                    : is_unsigned_ld
                        ? {24'b0, i_dmem_rdata[31:24]} // Unsigned byte 4th
                        : {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]}; // Signed byte 4th
              
endmodule