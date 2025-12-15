module mem_wb_reg(
    input i_clk, i_rst,

    input stall_thru, stall_kill,
    // Inputs
    input wire [31:0] i_pc, i_new_pc,
    input i_mem_read, i_reg_write_en,
    input wire [31:0] i_reg_out_1, i_reg_out_2,
    input [31:0] i_ex_data_out,
    input [4:0] i_rs1_addr, i_rs2_addr, i_rd_addr,
    input wire i_halt, i_valid,
    input wire i_rs1_used, i_rs2_used,
    input wire [31:0] i_instruction,
    input wire [31:0] i_dmem_addr,
    input wire i_dmem_ren, i_dmem_wen,
    input wire [3:0] i_dmem_mask,
    input wire [31:0] i_dmem_wdata,
    input wire i_is_word, i_is_h_or_b, i_is_unsigned_ld,
    input wire i_trap,

    // Outputs
    output wire [31:0] o_pc, o_new_pc,
    output wire o_mem_read, o_reg_write_en,
    output wire [31:0] o_reg_out_1, o_reg_out_2,
    output wire [31:0] o_ex_data_out,
    output wire [4:0] o_rs1_addr, o_rs2_addr, o_rd_addr,
    output wire o_halt, o_valid,
    output wire o_rs1_used, o_rs2_used,
    output wire [31:0] o_instruction,
    output wire [31:0] o_dmem_addr,
    output wire o_dmem_ren, o_dmem_wen,
    output wire [3:0] o_dmem_mask,
    output wire [31:0] o_dmem_wdata,
    output wire o_is_word, o_is_h_or_b, o_is_unsigned_ld,
    output wire o_trap
);

    localparam [31:0] NOP = 32'h00000013;


    wire [31:0] d_pc, d_new_pc, d_instruction, d_ex_data_out, d_reg_out_1, d_reg_out_2, d_dmem_addr, d_dmem_wdata;
    wire [4:0] d_rs1_addr, d_rs2_addr, d_rd_addr;
    wire [3:0] d_dmem_mask;
    wire d_mem_read, d_reg_write_en, d_halt, d_valid, d_rs1_used, d_rs2_used, d_dmem_ren, d_dmem_wen, d_is_word, d_is_h_or_b, d_is_unsigned_ld, d_trap;

    assign d_pc           = stall_thru | stall_kill ? o_pc           : i_pc;
    assign d_new_pc       = stall_thru | stall_kill ? o_new_pc       : i_new_pc;
    assign d_mem_read     = stall_thru | stall_kill ? o_mem_read     : i_mem_read;
    assign d_reg_write_en = stall_kill ? 1'b0 : stall_thru ? o_reg_write_en : i_reg_write_en;
    assign d_reg_out_1    = stall_thru | stall_kill ? o_reg_out_1    : i_reg_out_1;
    assign d_reg_out_2    = stall_thru | stall_kill ? o_reg_out_2    : i_reg_out_2;
    assign d_ex_data_out  = stall_thru | stall_kill ? o_ex_data_out  : i_ex_data_out;
    assign d_rs1_addr     = stall_thru | stall_kill ? o_rs1_addr     : i_rs1_addr;
    assign d_rs2_addr     = stall_thru | stall_kill ? o_rs2_addr     : i_rs2_addr;
    assign d_rs1_used     = stall_thru | stall_kill ? o_rs1_used     : i_rs1_used;
    assign d_rs2_used     = stall_thru | stall_kill ? o_rs2_used     : i_rs2_used;
    assign d_rd_addr      = stall_thru | stall_kill ? o_rd_addr      : i_rd_addr;  
    assign d_halt         = stall_thru | stall_kill ? o_halt         : i_halt;
    assign d_valid        = stall_kill ? 1'b0          : stall_thru ? o_valid        : i_valid;
    assign d_instruction  = stall_kill | stall_thru ? o_instruction  : i_instruction;
    assign d_dmem_addr    = stall_thru | stall_kill ? o_dmem_addr    : i_dmem_addr;
    assign d_dmem_ren     = stall_thru | stall_kill ? o_dmem_ren     : i_dmem_ren;
    assign d_dmem_wen     = stall_thru | stall_kill ? o_dmem_wen     : i_dmem_wen;
    assign d_dmem_mask    = stall_thru | stall_kill ? o_dmem_mask    : i_dmem_mask;
    assign d_dmem_wdata   = stall_thru | stall_kill ? o_dmem_wdata   : i_dmem_wdata;
    assign d_is_word      = stall_thru | stall_kill ? o_is_word      : i_is_word;
    assign d_is_h_or_b    = stall_thru | stall_kill ? o_is_h_or_b    : i_is_h_or_b;
    assign d_is_unsigned_ld = stall_thru | stall_kill ? o_is_unsigned_ld : i_is_unsigned_ld;
    assign d_trap         = stall_thru | stall_kill ? o_trap         : i_trap;


    d_ff #(.WIDTH(32)) pc_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_pc),
        .q(o_pc)
    );

    d_ff #(.WIDTH(32)) new_pc_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_new_pc),
        .q(o_new_pc)
    );

    d_ff #(.WIDTH(32)) instruction_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_instruction),
        .q(o_instruction)
    );

    d_ff mem_read_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_mem_read),
        .q(o_mem_read)
    );

    d_ff reg_write_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_reg_write_en),
        .q(o_reg_write_en)
    );

    d_ff halt_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_halt),
        .q(o_halt)
    );

    d_ff #(.WIDTH(32)) ex_data_out_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_ex_data_out),
        .q(o_ex_data_out)
    );

    d_ff #(.WIDTH(32)) reg_out_1_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_reg_out_1),
        .q(o_reg_out_1)
    );

    d_ff #(.WIDTH(32)) reg_out_2_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_reg_out_2),
        .q(o_reg_out_2)
    );

    d_ff #(.WIDTH(5)) rs1_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_rs1_addr),
        .q(o_rs1_addr)
    );

    d_ff #(.WIDTH(5)) rs2_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_rs2_addr),
        .q(o_rs2_addr)
    );

    d_ff #(.WIDTH(5)) rd_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_rd_addr),
        .q(o_rd_addr)
    );

    d_ff rs1_used_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_rs1_used),
        .q(o_rs1_used)
    );

    d_ff rs2_used_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_rs2_used),
        .q(o_rs2_used)
    );

    d_ff valid_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_valid),
        .q(o_valid)
    );

    d_ff #(.WIDTH(32)) dmem_addr_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_dmem_addr),
        .q(o_dmem_addr)
    );

    d_ff dmem_ren_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_dmem_ren),
        .q(o_dmem_ren)
    );

    d_ff dmem_wen_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_dmem_wen),
        .q(o_dmem_wen)
    );

    d_ff is_word_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_is_word),
        .q(o_is_word)
    );
    d_ff is_h_or_b_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_is_h_or_b),
        .q(o_is_h_or_b)
    );
    d_ff is_unsigned_ld_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_is_unsigned_ld),
        .q(o_is_unsigned_ld)
    );

    d_ff trap_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_trap),
        .q(o_trap)
    );

    d_ff #(.WIDTH(4)) dmem_mask_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_dmem_mask),
        .q(o_dmem_mask)
    );

    d_ff #(.WIDTH(32)) dmem_wdata_ff (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .d(d_dmem_wdata),
        .q(o_dmem_wdata)
    );
endmodule