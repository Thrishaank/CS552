module store(
    input clk, i_rst,
    input [31:0] address, w_data,
    input mem_read, mem_write, is_word, is_h_or_b, is_unsigned_ld,
    input [31:0] i_dmem_rdata,
    output [31:0] o_dmem_addr,
    output [31:0] o_dmem_wdata,
    output [3:0] o_dmem_mask
    output o_dmem_ren, o_dmem_wen,
    output [31:0] data_mem_out;
);

endmodule