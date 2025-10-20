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
    output wire halt
);


    // Used to specific immediate format (1 hot encoding)
    wire [5:0] i_format;

    imm u_imm (
        .i_inst (instruction),
        .i_format(i_format),
        .o_immediate  (imm_out)
    );

    // Indicates whether lt or eq output of alu should be check for branch
    assign check_lt_or_eq = instruction[14];
    // 
    assign branch_expect_n = instruction[12];

    wire [6:0] opcode   = instruction[6:0];
    wire [2:0] funct3   = instruction[14:12];
    wire funct7b5       = instruction[30];

    // Opcodes for unique operations
    localparam R_TYPE       = 7'b0110011;
    localparam NON_J_U_LOWER_4 = 4'b0011;
    localparam I_UPPER_2    = 2'b00;
    localparam IMM_ARITH    = 7'b0010011;  
    localparam LOAD         = 7'b0000011;  
    localparam STORE        = 7'b0100011;  
    localparam BRANCH       = 7'b1100011;  
    localparam JAL          = 7'b1101111;  
    localparam JALR         = 7'b1100111;  
    localparam LUI          = 7'b0110111;  
    localparam AUIPC        = 7'b0010111; 

    // Catch invalid opcodes
    assign decode_trap = ~(is_r | is_i | is_s | is_b | is_u | is_j | halt);

    // Extract addresses from instruction
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr = instruction[11:7];

    // Check opcodes for instruction type
    assign is_r = (opcode == R_TYPE);
    assign is_i = (opcode[3:0] == NON_J_U_LOWER_4 && opcode[6:5] == I_UPPER_2) | is_jalr;
    assign is_s  = (opcode == STORE);
    assign is_b = (opcode == BRANCH);
    assign is_u = (is_lui | is_auipc);
    assign is_j = is_jal;
    assign i_format = {is_j, is_u, is_b, is_s, is_i, 1'b0};

    // Check opcodes for specific instructions
    assign is_lui    = (opcode == LUI);
    assign is_auipc  = (opcode == AUIPC);
    wire is_jal = opcode == JAL;
    wire is_jalr = opcode == JALR;
    assign halt = opcode == 7'b1110011;

    // Other flags to controls muxes
    assign imm_alu      = ~(is_r | is_b); // Should IMM (1) or REG2 (0) be written to ALU
    assign reg_write    = ~(is_s | is_b); // Should we write to destination register
    wire is_load        = (is_i & ~opcode[4] & ~opcode[2]); // Is this a load instruction
    assign is_unsigned_ld = (is_load && funct3[2]); // is load unsigned
    assign mem_read     = is_load; // Should we read from memory
    assign mem_write    = is_s; // Should we write to memory
    assign branch       = is_b;  // Are we branching
    assign jump         = is_j | is_jalr; // Is there a jump occurring
    assign reg_jump     = is_jalr; // Do we have to use value from reg to jump
    assign is_word      = funct3[1]; // Are we dealing with word read/write
    assign is_h_or_b    = funct3[0]; // If we are not dealing with work, are we dealing with half-word (1) or byte (0)
    wire is_imm_arith   =  (is_i & opcode[4]); // Is this an arithmetic operation with imm

    //ALU Ctrl
    assign i_arith = funct7b5;
    assign i_opsel  = (is_r | is_imm_arith) ? funct3 : 3'b000;
    assign i_sub = (is_r & funct7b5);
    assign i_unsigned = funct3[0];

endmodule