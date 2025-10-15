module writeback(
    input clk, i_rst,
    input mem_read,
    input [31:0] data_mem_out, alu_result,
    output [31:0] reg_write_data
);

    assign reg_write_data = (mem_read) ? data_mem_out : alu_result;

endmodule