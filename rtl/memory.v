module memory(
    input i_clk, i_rst,
    input [31:0] address, w_data,
    input mem_read, mem_write, is_word, is_h_or_b, is_unsigned_ld,
    input [31:0] i_dmem_rdata,
    output [31:0] o_dmem_addr,
    output [31:0] o_dmem_wdata,
    output [3:0] o_dmem_mask,
    output o_dmem_ren, o_dmem_wen,
    output mem_trap
);

// Assign outputs to be input to data memory from module inputs
assign o_dmem_addr  = {address[31:2], 2'b00}; // Word align address
assign o_dmem_ren   = mem_read;
assign o_dmem_wen   = mem_write;

// Calculate mask based on lowest 2 bits of address
assign o_dmem_mask = is_word
    ? 4'b1111 // Is word, need all bits
    : is_h_or_b // Check if half-word or byte
        ? address[1] // Is half word, check which half of word we are dealing with 
            ? 4'b1100 
            : 4'b0011 
        : address[1:0] == 2'b00 // Is byte, figure out correct bit to mask
            ? 4'b0001
            : address[1:0] == 2'b01
                ? 4'b0010
                : address[1:0] == 2'b10
                    ? 4'b0100
                    : 4'b1000;

// Assign mem_data_out based on load type and address alignment
assign o_dmem_wdata = is_word
    ? w_data // If word
    : is_h_or_b
        ? address[1] // Is half-word, select correct half
            ? w_data << 16
            : w_data
        : address[1:0] == 2'b00 // If byte
            ? w_data
            : address[1:0] == 2'b01
                ? w_data << 8
                : address[1:0] == 2'b10
                    ? w_data << 16
                    : w_data << 24;

// Check if the address is unaligned and assert trap
assign mem_trap = (mem_read | mem_write) & 
                    ((is_word & |address[1:0]) | // Word access but not aligned
                    (is_h_or_b & address[0]));      // Half-word access but not aligned

endmodule