module decode(
    input i_clk, i_rst,
    input [31:0] instruction,
    input [31:0] reg_write_data,
    input [31:0] pc_plus4,
    input reg_write_en,
    output branch, imm_alu, check_lt_or_eq, branch_expect_n, jump, reg_jump, 
    output i_arith, i_unsigned, i_sub,
    output [2:0] i_opsel,
    output is_auipc, is_lui,
    output [4:0] rs1_addr, rs2_addr, rd_addr,
    output [31:0] imm_out,
    output mem_read, mem_write, is_word, is_h_or_b, is_unsigned_ld,
    output reg_write,
    output wire is_r,
    output wire is_i,
    output wire is_s,
    output wire is_b,
    output wire is_u,
    output wire is_j,
    output wire decode_trap,
);

    wire [5:0] i_format;

    imm u_imm (
        .i_inst (instruction),
        .i_format(i_format),
        .o_immediate  (imm_out)
    );

    assign check_lt_or_eq = instruction[14];
    assign branch_expect_n = instruction[12];

    wire [6:0] opcode     = instruction[6:0];
    wire [2:0] funct3     = instruction[14:12];
    wire funct7b5   = instruction[30];

    localparam R_TYPE    = 7'b0110011;
    localparam NON_J_U_LOWER_4   = 4'b0011;
    localparam I_UPPER_2 = 2'b00;
    localparam IMM_ARITH    = 7'b0010011;  
    localparam J_LOWER_3 = 3'b111;
    localparam J_UPPER_3 = 3'b110;
    localparam LOAD      = 7'b0000011;  
    localparam STORE     = 7'b0100011;  
    localparam BRANCH    = 7'b1100011;  
    localparam JAL       = 7'b1101111;  
    localparam JALR      = 7'b1100111;  
    localparam LUI       = 7'b0110111;  
    localparam AUIPC     = 7'b0010111; 


    wire invalid_funct3 = (is_load  & (funct3 > 3'b101)) |
                          (is_s     & (funct3 > 3'b010)) |
                          (is_b     & (funct3 = 3'b010) |(funct3 = 3'b011) ) |
                          (is_r     & (~(funct3 inside {3'b000,3'b001,3'b010,3'b011,3'b100,3'b101,3'b110,3'b111})));

    assign decode_trap = ~(is_r | is_i | is_s | is_b | is_u | is_j) | (invalid_funct3);


    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr = instruction[11:7];

    assign is_r = (opcode == R_TYPE);
    assign is_i = (opcode[3:0] == NON_J_U_LOWER_4 && opcode[6:5] == I_UPPER_2);
    wire is_imm_arith  = (is_i & opcode[4]);
    wire is_load   = (is_i & ~opcode[4]);
    assign is_s  = (opcode == STORE);
    assign is_b = (opcode == BRANCH);
    assign is_lui    = (opcode == LUI);
    assign is_auipc  = (opcode == AUIPC);
    assign is_u = (is_lui | is_auipc);
    assign is_j = (opcode[2:0] == J_LOWER_3 && opcode[6:4] == J_UPPER_3);

    // Make better
    assign i_format = {is_j, is_u, is_b, is_s, is_i, 1'b0};

    assign imm_alu = ~(is_r | is_b);
    assign reg_write = ~(is_s | is_b);
    assign mem_read = is_load;
    assign mem_write = is_s;
    assign branch   = is_b;
    assign jump       = is_j;
    assign reg_jump   = is_j & ~opcode[3];
    assign is_word       = ( (is_load | is_s) && (funct3 == 3'b010) );
    assign is_h_or_b     = ( (is_load | is_s) && (funct3[1:0] != 2'b10) );
    assign is_unsigned_ld= ( is_load && funct3[2] );

    //ALU Ctrl
    assign i_arith = funct7b5;
    assign i_opsel  = (is_r | is_imm_arith) ? funct3 : 3'b000;
    assign i_sub = (is_r & funct7b5);
    assign i_unsigned = funct3[0];

endmodule