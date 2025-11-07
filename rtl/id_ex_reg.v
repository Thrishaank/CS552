`default_nettype none
////////////PLEASE DELETE/ ADD SIGNALS AS NECESSARY/////////////
// ID/EX Pipeline Register
// Holds data between Decode and Execute stages
module id_ex_reg (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_stall,       // Stall signal to hold current values
    input  wire        i_flush,       // Flush signal to clear pipeline register
    
    // Data path signals from ID stage (Decode)
    input  wire [31:0] i_pc,          // Program Counter
    input  wire [31:0] i_reg_out_1,   // Register Read Data 1 (rs1)
    input  wire [31:0] i_reg_out_2,   // Register Read Data 2 (rs2)
    input  wire [31:0] i_imm,         // Immediate value from decode
    input  wire [ 4:0] i_rs1_addr,    // Source register 1 address (for forwarding)
    input  wire [ 4:0] i_rs2_addr,    // Source register 2 address (for forwarding)
    input  wire [ 4:0] i_rd_addr,     // Destination register address

    input wire i_rs1_used,
    output wire o_rs1_used,
    input wire i_rs2_used,
    output wire o_rs2_used,
    
    // Control signals from ID stage - Memory operations
    input  wire        i_mem_read,    // Memory read enable
    input  wire        i_mem_write,   // Memory write enable
    input  wire        i_is_word,     // Word operation (vs byte/half)
    input  wire        i_is_h_or_b,   // Halfword or byte operation
    input  wire        i_is_unsigned_ld, // Unsigned load
    
    // Control signals - ALU/Execute operations
    input  wire        i_reg_write_en,   // Register write enable
    input  wire        i_imm_alu,     // Use immediate in ALU (vs reg)
    input  wire        i_i_arith,     // Arithmetic shift right
    input  wire        i_i_unsigned,  // Unsigned comparison
    input  wire        i_i_sub,       // Subtraction
    input  wire [ 2:0] i_i_opsel,     // ALU operation select
    input  wire        i_is_auipc,    // Add upper immediate to PC
    input  wire        i_is_lui,      // Load upper immediate
    
    // Control signals - Branch/Jump operations
    input  wire        i_branch,      // Branch instruction
    input  wire        i_jump,        // Jump instruction
    input  wire        i_is_jalr,    // Register-based jump (JALR)
    input  wire        i_check_lt_or_eq,   // Check less-than or equal for branch
    input  wire        i_branch_expect_n,  // Branch prediction (not taken)
    
    // Exception/Control flow
    input  wire        i_decode_trap, // Decode trap flag
    input  wire        i_halt,        // Halt instruction
    input  wire        i_valid,

    input wire [31:0] i_instruction,
    output wire [31:0] o_instruction,
    
    // Data path outputs to EX stage
    output wire [31:0] o_pc,
    output wire [31:0] o_reg_out_1,
    output wire [31:0] o_reg_out_2,
    output wire [31:0] o_imm,
    output wire [ 4:0] o_rs1_addr,
    output wire [ 4:0] o_rs2_addr,
    output wire [ 4:0] o_rd_addr,
    
    // Control outputs - Memory operations
    output wire        o_mem_read,
    output wire        o_mem_write,
    output wire        o_is_word,
    output wire        o_is_h_or_b,
    output wire        o_is_unsigned_ld,
    
    // Control outputs - ALU/Execute operations
    output wire        o_reg_write_en,
    output wire        o_imm_alu,
    output wire        o_i_arith,
    output wire        o_i_unsigned,
    output wire        o_i_sub,
    output wire [ 2:0] o_i_opsel,
    output wire        o_is_auipc,
    output wire        o_is_lui,
    
    // Control outputs - Branch/Jump operations
    output wire        o_branch,
    output wire        o_jump,
    output wire        o_is_jalr,
    output wire        o_check_lt_or_eq,
    output wire        o_branch_expect_n,
    
    // Exception/Control flow outputs
    output wire        o_decode_trap,
    output wire        o_halt,
    output wire        o_valid
);

    // Internal wires for mux outputs (D inputs to flip-flops)
    // Data path
    wire [31:0] d_pc, d_reg_out_1, d_reg_out_2, d_imm;
    wire [ 4:0] d_rs1_addr, d_rs2_addr, d_rd_addr;
    
    // Memory control
    wire        d_mem_read, d_mem_write, d_is_word, d_is_h_or_b, d_is_unsigned_ld;
    
    // ALU control
    wire        d_reg_write, d_imm_alu, d_i_arith, d_i_unsigned, d_i_sub;
    wire [ 2:0] d_i_opsel;
    wire        d_is_auipc, d_is_lui;
    
    // Branch/Jump control
    wire        d_branch, d_jump, d_is_jalr, d_check_lt_or_eq, d_branch_expect_n;
    
    // Exception/Control
    wire        d_decode_trap, d_halt;
    
    // Reset signal: combine rst and flush (clear pipeline bubble on flush)
    wire rst_or_flush;
    assign rst_or_flush = i_rst | i_flush;
    
    // ====================================================================
    // Stall Multiplexers: When stalled, hold current output value
    // ====================================================================
    
    // Data path signals
    assign d_pc          = i_stall ? o_pc          : i_pc;
    assign d_reg_out_1   = i_stall ? o_reg_out_1   : i_reg_out_1;
    assign d_reg_out_2   = i_stall ? o_reg_out_2   : i_reg_out_2;
    assign d_imm         = i_stall ? o_imm         : i_imm;
    assign d_rs1_addr    = i_stall ? o_rs1_addr    : i_rs1_addr;
    assign d_rs2_addr    = i_stall ? o_rs2_addr    : i_rs2_addr;
    assign d_rd_addr     = i_stall ? o_rd_addr     : i_rd_addr;
    
    // Memory control signals
    assign d_mem_read       = i_stall ? o_mem_read       : i_mem_read;
    assign d_mem_write      = i_stall ? o_mem_write      : i_mem_write;
    assign d_is_word        = i_stall ? o_is_word        : i_is_word;
    assign d_is_h_or_b      = i_stall ? o_is_h_or_b      : i_is_h_or_b;
    assign d_is_unsigned_ld = i_stall ? o_is_unsigned_ld : i_is_unsigned_ld;
    
    // ALU control signals
    assign d_reg_write  = i_stall ? o_reg_write_en  : i_reg_write_en;
    assign d_imm_alu    = i_stall ? o_imm_alu    : i_imm_alu;
    assign d_i_arith    = i_stall ? o_i_arith    : i_i_arith;
    assign d_i_unsigned = i_stall ? o_i_unsigned : i_i_unsigned;
    assign d_i_sub      = i_stall ? o_i_sub      : i_i_sub;
    assign d_i_opsel    = i_stall ? o_i_opsel    : i_i_opsel;
    assign d_is_auipc   = i_stall ? o_is_auipc   : i_is_auipc;
    assign d_is_lui     = i_stall ? o_is_lui     : i_is_lui;
    
    // Branch/Jump control signals
    assign d_branch          = i_stall ? o_branch          : i_branch;
    assign d_jump            = i_stall ? o_jump            : i_jump;
    assign d_is_jalr        = i_stall ? o_is_jalr        : i_is_jalr;
    assign d_check_lt_or_eq  = i_stall ? o_check_lt_or_eq  : i_check_lt_or_eq;
    assign d_branch_expect_n = i_stall ? o_branch_expect_n : i_branch_expect_n;
    
    // Exception/Control signals
    assign d_decode_trap = i_stall ? o_decode_trap : i_decode_trap;
    assign d_halt        = i_stall ? o_halt        : i_halt;
    
    // ====================================================================
    // D Flip-Flop Instantiations
    // ====================================================================
    
    // Data path flip-flops (32-bit)
    d_ff #(.WIDTH(32), .RST_VAL(32'h00000000)) ff_pc        (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_pc),        .q(o_pc));
    d_ff #(.WIDTH(32), .RST_VAL(32'h00000000)) ff_reg_out_1 (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_reg_out_1), .q(o_reg_out_1));
    d_ff #(.WIDTH(32), .RST_VAL(32'h00000000)) ff_reg_out_2 (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_reg_out_2), .q(o_reg_out_2));
    d_ff #(.WIDTH(32), .RST_VAL(32'h00000000)) ff_imm       (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_imm),       .q(o_imm));
    d_ff #(.WIDTH(32), .RST_VAL(32'h00000013)) ff_instruction (.i_clk(i_clk), .i_rst(rst_or_flush), .d(i_stall ? o_instruction : i_instruction), .q(o_instruction));

    // Address flip-flops (5-bit) - for forwarding unit
    d_ff #(.WIDTH(5), .RST_VAL(5'h00)) ff_rs1_addr (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_rs1_addr), .q(o_rs1_addr));
    d_ff #(.WIDTH(5), .RST_VAL(5'h00)) ff_rs2_addr (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_rs2_addr), .q(o_rs2_addr));
    d_ff #(.WIDTH(5), .RST_VAL(5'h00)) ff_rd_addr  (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_rd_addr),  .q(o_rd_addr));
    
    // Memory control flip-flops
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_mem_read       (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_mem_read),       .q(o_mem_read));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_mem_write      (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_mem_write),      .q(o_mem_write));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_is_word        (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_is_word),        .q(o_is_word));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_is_h_or_b      (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_is_h_or_b),      .q(o_is_h_or_b));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_is_unsigned_ld (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_is_unsigned_ld), .q(o_is_unsigned_ld));
    
    // ALU control flip-flops
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_reg_write  (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_reg_write),  .q(o_reg_write_en));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_imm_alu    (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_imm_alu),    .q(o_imm_alu));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_i_arith    (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_i_arith),    .q(o_i_arith));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_i_unsigned (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_i_unsigned), .q(o_i_unsigned));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_i_sub      (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_i_sub),      .q(o_i_sub));
    d_ff #(.WIDTH(3), .RST_VAL(3'h0)) ff_i_opsel    (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_i_opsel),    .q(o_i_opsel));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_is_auipc   (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_is_auipc),   .q(o_is_auipc));
    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) ff_is_lui     (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_is_lui),     .q(o_is_lui));
    
    // Branch/Jump control flip-flops
    d_ff ff_branch          (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_branch),          .q(o_branch));
    d_ff ff_jump            (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_jump),            .q(o_jump));
    d_ff ff_jalr           (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_is_jalr),        .q(o_is_jalr));
    d_ff ff_check_lt_or_eq  (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_check_lt_or_eq),  .q(o_check_lt_or_eq));
    d_ff ff_branch_expect_n (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_branch_expect_n), .q(o_branch_expect_n));

    // Signals for retire flip-flops

    d_ff rs1_used_dff(.i_rst(rst_or_flush), .i_clk(i_clk), .d(i_rs1_used), .q(o_rs1_used));
    d_ff rs2_used_dff(.i_rst(rst_or_flush), .i_clk(i_clk), .d(i_rs2_used), .q(o_rs2_used));
    
    // Exception/Control flip-flops
    d_ff ff_decode_trap (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_decode_trap), .q(o_decode_trap));
    d_ff ff_halt        (.i_clk(i_clk), .i_rst(rst_or_flush), .d(d_halt),        .q(o_halt));
    d_ff ff_valid       (.i_clk(i_clk), .i_rst(rst_or_flush), .d(i_stall ? 1'b0 : i_valid), .q(o_valid));

endmodule

`default_nettype wire
