module mem_wb_reg(
    input i_clk, i_rst,
    // Inputs
    input wire [31:0] i_pc, i_new_pc,
    input i_mem_read, i_reg_write_en,
    input wire [31:0] i_reg_out_1, i_reg_out_2,
    input [31:0] i_mem_data_out, i_ex_data_out,
    input [4:0] i_rs1_addr, i_rs2_addr, i_rd_addr,
    input wire i_halt, i_valid,
    input wire i_rs1_used, i_rs2_used,
    input wire [31:0] i_instruction,
    input wire [31:0] i_dmem_addr,
    input wire i_dmem_ren, i_dmem_wen,
    input wire [3:0] i_dmem_mask,
    input wire [31:0] i_dmem_wdata, i_dmem_rdata,

    // Outputs
    output wire [31:0] o_pc, o_new_pc,
    output wire o_mem_read, o_reg_write_en,
    output wire [31:0] o_reg_out_1, o_reg_out_2,
    output wire [31:0] o_mem_data_out, o_ex_data_out,
    output wire [4:0] o_rs1_addr, o_rs2_addr, o_rd_addr,
    output wire o_halt, o_valid,
    output wire o_rs1_used, o_rs2_used,
    output wire [31:0] o_instruction,
    output wire [31:0] o_dmem_addr,
    output wire o_dmem_ren, o_dmem_wen,
    output wire [3:0] o_dmem_mask,
    output wire [31:0] o_dmem_wdata, o_dmem_rdata
);

    d_ff #(.WIDTH(32)) pc_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_pc),
        .q(o_pc)
    );

    d_ff #(.WIDTH(32)) new_pc_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_new_pc),
        .q(o_new_pc)
    );

    d_ff #(.WIDTH(32)) instruction_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_instruction),
        .q(o_instruction)
    );

    d_ff mem_read_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_mem_read),
        .q(o_mem_read)
    );

    d_ff reg_write_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_reg_write_en),
        .q(o_reg_write_en)
    );

    d_ff halt_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_halt),
        .q(o_halt)
    );

    d_ff #(.WIDTH(32)) mem_data_out_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_mem_data_out),
        .q(o_mem_data_out)
    );

    d_ff #(.WIDTH(32)) ex_data_out_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_ex_data_out),
        .q(o_ex_data_out)
    );

    d_ff #(.WIDTH(32)) reg_out_1_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_reg_out_1),
        .q(o_reg_out_1)
    );

    d_ff #(.WIDTH(32)) reg_out_2_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_reg_out_2),
        .q(o_reg_out_2)
    );

    d_ff #(.WIDTH(5)) rs1_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_rs1_addr),
        .q(o_rs1_addr)
    );

    d_ff #(.WIDTH(5)) rs2_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_rs2_addr),
        .q(o_rs2_addr)
    );

    d_ff #(.WIDTH(5)) rd_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_rd_addr),
        .q(o_rd_addr)
    );

    d_ff rs1_used_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_rs1_used),
        .q(o_rs1_used)
    );

    d_ff rs2_used_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_rs2_used),
        .q(o_rs2_used)
    );

    d_ff valid_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_valid),
        .q(o_valid)
    );

    d_ff #(.WIDTH(32)) dmem_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_dmem_addr),
        .q(o_dmem_addr)
    );

    d_ff dmem_ren_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_dmem_ren),
        .q(o_dmem_ren)
    );

    d_ff dmem_wen_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_dmem_wen),
        .q(o_dmem_wen)
    );

    d_ff #(.WIDTH(4)) dmem_mask_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_dmem_mask),
        .q(o_dmem_mask)
    );

    d_ff #(.WIDTH(32)) dmem_wdata_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_dmem_wdata),
        .q(o_dmem_wdata)
    );

    d_ff #(.WIDTH(32)) dmem_rdata_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(i_dmem_rdata),
        .q(o_dmem_rdata)
    );

endmodule