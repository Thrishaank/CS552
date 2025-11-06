module decode(
    input i_clk, i_rst,
    input [31:0] instruction,
    input flush_decode,     // Real pipeline flush from execute (always-not-taken predictor)
    // Load-use hazard inputs from EX stage (ID/EX pipeline register)
    // Forwarding inputs from MEM stage (EX/MEM pipeline register)
    input [4:0] mem_rd_addr, // MEM stage destination register
    input ex_mem_read,      // EX stage is load instruction
    input prev_valid,      // Previous stage valid signal
    input [4:0] ex_rd_addr,  // EX stage destination register
    output branch, imm_alu, check_lt_or_eq, branch_expect_n, jump, is_jalr,
    output i_arith, i_unsigned, i_sub,
    output [2:0] i_opsel,
    output is_auipc, is_lui,
    output [4:0] rs1_addr, rs2_addr, rd_addr,
    output [31:0] imm_out,
    output mem_read, mem_write, is_word, is_h_or_b, is_unsigned_ld,
    output reg_write_en,
    output stall_pipeline,  // Asserted when load-use hazard detected
    output wire rs1_used,
    output wire rs2_used,
    output wire decode_trap,
    output wire halt,
    output wire valid
);
    // TODO: Correctly handle no op, make sure no reg is written to //DONE
    // TODO: Output no op if jump or branch success from execute //DONE
    // TODO: Bypassing //DONE

    // Used to specific immediate format (1 hot encoding)
    wire [5:0] i_format;

    // flush_decode is driven by execute via top-level wiring.
    // When asserted for one cycle, decode outputs a bubble (NOP).

    wire is_r, is_i, is_s, is_b, is_u, is_j;

    assign rs1_used = ~(is_u & is_j);  // rs1 not used by U and J types
    assign rs2_used = ~(is_i | is_u | is_j);  // rs2 not used by I, U, J types

    wire load_use_rs1 = ex_mem_read && (ex_rd_addr != 5'd0) && (ex_rd_addr == rs1_addr) && rs1_used;
    wire load_use_rs2 = ex_mem_read && (ex_rd_addr != 5'd0) && (ex_rd_addr == rs2_addr) && rs2_used;

    // Stall pipeline when load-use hazard detected
    // With forwarding, other RAW hazards don't require stalling
    assign stall_pipeline = load_use_rs1 | load_use_rs2;

    assign valid = prev_valid & ~stall_pipeline /*& ~flush_decode*/;
    
    // Flush implementation:
    // - flush_decode input (line 7) will be connected to execute.o_flush_pipeline in hart.v
    // - execute.o_flush_pipeline = o_branch_taken | i_jump (asserted when control flow changes)
    // - When flush_decode=1, all control signals are disabled (lines 139-145) creating a NOP
    // - This implements recovery for the always-not-taken branch predictor
    
    imm u_imm (
        .i_inst (instruction),
        .i_format(i_format),
        .o_immediate  (imm_out)
    );

    // Indicates whether lt or eq output of alu should be check for branch
    assign check_lt_or_eq = instruction[14];
    // Indicates expected branch outcome (1 = not equal/greater than, 0 = equal/less than)
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
    assign is_j = (opcode == JAL);
    assign i_format = {is_j, is_u, is_b, is_s, is_i, 1'b0};

    // Check opcodes for specific instructions
    assign is_lui    = (opcode == LUI);
    assign is_auipc  = (opcode == AUIPC);
    assign halt = opcode == 7'b1110011;

    // Other flags to controls muxes
    assign imm_alu      = ~(is_r | is_b); // Should IMM (1) or REG2 (0) be written to ALU
    // Do not write a register for stores/branches, or on halt/illegal, or on flush (NOP behavior)
    assign reg_write_en    = ~(is_s | is_b) & ~halt /*& ~decode_trap & ~flush_decode*/; // Should we write to destination register
    wire is_load        = (is_i & ~opcode[4] & ~opcode[2]); // Is this a load instruction
    assign is_unsigned_ld = (is_load && funct3[2]); // is load unsigned
    assign mem_read     = is_load /* ~flush_decode*/; // Kill on flush
    assign mem_write    = is_s /*& ~flush_decode*/; // Kill on flush
    assign branch       = is_b /*& ~flush_decode*/;  // Kill on flush
    assign jump         = (is_j | is_jalr) /*& ~flush_decode*/; // Kill on flush
    assign is_jalr     = opcode == JALR /*& ~flush_decode*/; // Kill on flush
    assign is_word      = funct3[1]; // Are we dealing with word read/write
    assign is_h_or_b    = funct3[0]; // If we are not dealing with work, are we dealing with half-word (1) or byte (0)
    wire is_imm_arith   =  (is_i & opcode[4]); // Is this an arithmetic operation with imm

    //ALU Ctrl
    assign i_arith = funct7b5;
    assign i_opsel  = (is_r | is_imm_arith) ? funct3 : 3'b000;
    assign i_sub = (is_r & funct7b5);
    assign i_unsigned = funct3[0];

endmodule