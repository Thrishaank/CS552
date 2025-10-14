`default_nettype none

// The arithmetic logic unit (ALU) is responsible for performing the core
// calculations of the processor. It takes two 32-bit operands and outputs
// a 32 bit result based on the selection operation - addition, comparison,
// shift, or logical operation. This ALU is a purely combinational block, so
// you should not attempt to add any registers or pipeline it in phase 3.
module alu (
    // Major operation selection.
    // NOTE: In order to simplify instruction decoding in phase 4, both 3'b010
    // and 3'b011 are used for set less than (they are equivalent).
    // Unsigned comparison is controlled through the `i_unsigned` signal.
    //
    // 3'b000: addition/subtraction if `i_sub` asserted
    // 3'b001: shift left logical
    // 3'b010,
    // 3'b011: set less than/unsigned if `i_unsigned` asserted
    // 3'b100: exclusive or
    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
    // 3'b110: or
    // 3'b111: and
    input  wire [2:0] i_opsel,
    // When asserted, addition operations should subtract instead.
    // This is only used for `i_opsel == 3'b000` (addition/subtraction).
    input  wire        i_sub,
    // When asserted, comparison operations should be treated as unsigned.
    // This is only used for branch comparisons and set less than.
    // For branch operations, the ALU result is not used, only the comparison
    // results.
    input  wire        i_unsigned,
    // When asserted, right shifts should be treated as arithmetic instead of
    // logical. This is only used for `i_opsel == 3'b011` (shift right).
    input  wire        i_arith,
    // First 32-bit input operand.
    input  wire [31:0] i_op1,
    // Second 32-bit input operand.
    input  wire [31:0] i_op2,
    // 32-bit output result. Any carry out (from addition) should be ignored.
    output wire [31:0] o_result,
    // Equality result. This is used downstream to determine if a
    // branch should be taken.
    output wire        o_eq,
    // Set less than result. This is used downstream to determine if a
    // branch should be taken.
    output wire        o_slt
);
    wire signed [31:0] result_s;
    wire [31:0] shifted;

    assign result_s = (i_opsel === 3'b000) ? (i_op1 + (i_op2 ^ {32{i_sub}}) + i_sub) : // add/sub
                        ((i_opsel === 3'b001) ? (i_op1 << i_op2[4:0]): // sll
                        ((i_opsel === 3'b100) ? (i_op1 ^ i_op2) : // xor
                        ((i_opsel === 3'b101) ? shifted: // sra/srl
                        ((i_opsel === 3'b110) ? (i_op1 | i_op2) : 
                        ((i_opsel === 3'b111) ? (i_op1 & i_op2) : 
                        (i_unsigned ? {31'b0, (i_op1 < i_op2)} : {31'b0, ($signed(i_op1) < $signed(i_op2))})
                        )))));
    
    assign shifted = (i_op2[4:0] === 5'h1) ? {{1{i_op1[31] & i_arith}}, i_op1[31:1]} :
                        (i_op2[4:0] === 5'h2) ? {{2{i_op1[31] & i_arith}}, i_op1[31:2]}:
                        (i_op2[4:0] === 5'h3) ? {{3{i_op1[31] & i_arith}}, i_op1[31:3]}:
                        (i_op2[4:0] === 5'h4) ? {{4{i_op1[31] & i_arith}}, i_op1[31:4]}:
                        (i_op2[4:0] === 5'h5) ? {{5{i_op1[31] & i_arith}}, i_op1[31:5]}:
                        (i_op2[4:0] === 5'h6) ? {{6{i_op1[31] & i_arith}}, i_op1[31:6]}:
                        (i_op2[4:0] === 5'h7) ? {{7{i_op1[31] & i_arith}}, i_op1[31:7]}:
                        (i_op2[4:0] === 5'h8) ? {{8{i_op1[31] & i_arith}}, i_op1[31:8]}:
                        (i_op2[4:0] === 5'h9) ? {{9{i_op1[31] & i_arith}}, i_op1[31:9]}:
                        (i_op2[4:0] === 5'hA) ? {{10{i_op1[31] & i_arith}}, i_op1[31:10]}:
                        (i_op2[4:0] === 5'hB) ? {{11{i_op1[31] & i_arith}}, i_op1[31:11]}:
                        (i_op2[4:0] === 5'hC) ? {{12{i_op1[31] & i_arith}}, i_op1[31:12]}:
                        (i_op2[4:0] === 5'hD) ? {{13{i_op1[31] & i_arith}}, i_op1[31:13]}:
                        (i_op2[4:0] === 5'hE) ? {{14{i_op1[31] & i_arith}}, i_op1[31:14]}:
                        (i_op2[4:0] === 5'hF) ? {{15{i_op1[31] & i_arith}}, i_op1[31:15]}:
                        (i_op2[4:0] === 5'h10) ?{{16{i_op1[31] & i_arith}}, i_op1[31:16]}:
                        (i_op2[4:0] === 5'h11) ?{{17{i_op1[31] & i_arith}}, i_op1[31:17]}:
                        (i_op2[4:0] === 5'h12) ?{{18{i_op1[31] & i_arith}}, i_op1[31:18]}:
                        (i_op2[4:0] === 5'h13) ?{{19{i_op1[31] & i_arith}}, i_op1[31:19]}:
                        (i_op2[4:0] === 5'h14) ?{{20{i_op1[31] & i_arith}}, i_op1[31:20]}:
                        (i_op2[4:0] === 5'h15) ?{{21{i_op1[31] & i_arith}}, i_op1[31:21]}:
                        (i_op2[4:0] === 5'h16) ?{{22{i_op1[31] & i_arith}}, i_op1[31:22]}:
                        (i_op2[4:0] === 5'h17) ?{{23{i_op1[31] & i_arith}}, i_op1[31:23]}:
                        (i_op2[4:0] === 5'h18) ?{{24{i_op1[31] & i_arith}}, i_op1[31:24]}:
                        (i_op2[4:0] === 5'h19) ?{{25{i_op1[31] & i_arith}}, i_op1[31:25]}:
                        (i_op2[4:0] === 5'h1A) ?{{26{i_op1[31] & i_arith}}, i_op1[31:26]}:
                        (i_op2[4:0] === 5'h1B) ?{{27{i_op1[31] & i_arith}}, i_op1[31:27]}:
                        (i_op2[4:0] === 5'h1C) ?{{28{i_op1[31] & i_arith}}, i_op1[31:28]}:
                        (i_op2[4:0] === 5'h1D) ?{{29{i_op1[31] & i_arith}}, i_op1[31:29]}:
                        (i_op2[4:0] === 5'h1E) ?{{30{i_op1[31] & i_arith}}, i_op1[31:30]}:
                        (i_op2[4:0] === 5'h1F) ?{{31{i_op1[31] & i_arith}}, i_op1[31]}: i_op1;
    assign o_eq = (i_op1 === i_op2);
    assign o_slt = i_unsigned ? (i_op1 < i_op2) : ($signed(i_op1) < $signed(i_op2));
    assign o_result = result_s;
endmodule

`default_nettype wire
