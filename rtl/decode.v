module decode(
    input clk, i_rst,
    input [31:0] instruction,
    input [31:0] reg_write_data,
    input [31:0] pc_plus4,
    output reg branch, mem_read, mem_write, regWrite, MemtoReg, ALUSrc,
    output reg [1:0]immALU, 
    output check_lt_or_eq, branch_expect_n, jump, reg_jump, is_word, is_h_or_b, is_unsigned_ld, 
    output reg i_arith, i_unsigned, i_sub,
    output reg [2:0] i_opsel,
    output [31:0] reg_out_1, reg_out_2, imm_out
);
  rf u_rf (
    .i_clk       (clk),
    .i_rst       (i_rst),
    .i_rs1_raddr (instruction[19:15]),
    .o_rs1_rdata (reg_out_1),
    .i_rs2_raddr (instruction[24:20]),
    .o_rs2_rdata (reg_out_2),
    .i_rd_wen    (regWrite),
    .i_rd_waddr  (instruction[11:7]),
    .i_rd_wdata  (reg_write_data)
  );
    imm u_imm (
    .i_inst (instruction),
    .o_immediate  (imm_out)
  );
    //  i_rs1_raddr = instruction[19:15];
    //  i_rs2_raddr = instruction[24:20];
    //  i_rd_waddr = instruction[11:7];
    //  i_inst = instruction;

    assign check_lt_or_eq = instruction[14];
    assign branch_expect_n = instruction[12];

  wire [6:0] opcode     = instruction[6:0];
  wire [2:0] funct3     = instruction[14:12];
  wire funct7b5   = instruction[30];

    localparam R_TYPE    = 7'b0110011;  
    localparam I_TYPE    = 7'b0010011;  
    localparam LOAD      = 7'b0000011;  
    localparam STORE     = 7'b0100011;  
    localparam BRANCH    = 7'b1100011;  
    localparam JAL       = 7'b1101111;  
    localparam JALR      = 7'b1100111;  
    localparam LUI       = 7'b0110111;  
    localparam AUIPC     = 7'b0010111;  

  wire is_rtype  = (opcode == R_TYPE);
  wire is_itype  = (opcode == I_TYPE);
  wire is_load   = (opcode == LOAD);
  wire is_store  = (opcode == STORE);
  wire is_branch = (opcode == BRANCH);
  wire is_jal    = (opcode == JAL);
  wire is_jalr   = (opcode == JALR);
  wire is_lui    = (opcode == LUI);
  wire is_auipc  = (opcode == AUIPC);

  assign ALUSrc   = is_itype | is_load | is_store | is_jalr | is_lui | is_auipc;
  assign MemtoReg = is_load;                       
  assign regWrite = is_rtype | is_itype | is_load | is_jal | is_jalr | is_lui | is_auipc;
  assign mem_read = is_load;
  assign mem_write= is_store;
  assign branch   = is_branch;
  assign immALU   = ({2{is_branch}} & 2'b01) | ({2{is_rtype | is_itype}} & 2'b10)
                  | ({2{is_load | is_store | is_jal | is_jalr | is_lui | is_auipc}} & 2'b00);
  assign jump       = is_jal;
  assign reg_jump   = is_jalr;
  assign is_word       = ( (is_load | is_store) && (funct3 == 3'b010) );
  assign is_h_or_b     = ( (is_load | is_store) && (funct3[1:0] != 2'b10) );
  assign is_unsigned_ld= ( is_load && funct3[2] );

//ALU Ctrl
  assign i_arith  = 1'b1;
  assign i_opsel  = (immALU == 2'b10) ? funct3 : 3'b000;
  assign i_sub = (immALU == 2'b01) ? 1'b1 : (immALU == 2'b10) ? 
                ( (funct3 == 3'b000) ? funct7b5 :(funct3 == 3'b101) ? funct7b5 :1'b0 ) : 1'b0;
  assign i_unsigned = (immALU == 2'b01) ? funct3[2] :(immALU == 2'b10) ? (funct3 == 3'b011) : 1'b0;


endmodule