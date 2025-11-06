`default_nettype none

// IF/ID Pipeline Register
// Holds data between Instruction Fetch and Decode stages
module if_id_reg (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_stall,       // Stall signal to hold current values
    input  wire        i_flush,       // Flush signal to clear pipeline register
    
    // Inputs from IF stage
    input  wire [31:0] i_instruction, // Instruction from fetch
    input  wire [31:0] i_pc,          // Program counter from fetch
    input wire i_valid,
    
    // Outputs to ID stage
    output wire [31:0] o_instruction, // Instruction to decode
    output wire [31:0] o_pc,           // Program counter to decode
    output wire o_valid
);

    // NOP instruction (addi x0, x0, 0) = 32'h00000013
    localparam [31:0] NOP = 32'h00000013;
    
    // Reset signal: combine rst and flush
    wire rst_or_flush;
    assign rst_or_flush = i_rst | i_flush;
    
    // Multiplexers for stall logic
    // When stalled, hold current values; otherwise, accept new values from fetch
    wire [31:0] d_instruction, d_pc;
    assign d_instruction = i_stall ? o_instruction : i_instruction;
    assign d_pc          = i_stall ? o_pc          : i_pc;
    
    // Instantiate D flip-flops for each signal
    // On reset or flush, instruction becomes NOP, PC becomes 0
    d_ff #(.WIDTH(32), .RST_VAL(NOP)) ff_instruction (
        .i_clk(i_clk),
        .i_rst(rst_or_flush),
        .d(d_instruction),
        .q(o_instruction)
    );
    
    d_ff #(.WIDTH(32), .RST_VAL(32'h00000000)) ff_pc (
        .i_clk(i_clk),
        .i_rst(rst_or_flush),
        .d(d_pc),
        .q(o_pc)
    );

    d_ff ff_valid (
        .i_clk(i_clk),
        .i_rst(rst_or_flush),
        .d(i_stall ? 1'b0 : i_valid),
        .q(o_valid)
    );

endmodule

`default_nettype wire
