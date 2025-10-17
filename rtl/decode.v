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

    //2'b00 - "Just do ADD for address calculation"
    //2'b01 - "Just do SUB for comparison"
    //2'b10 - "Look at funct3/funct7 to decide what to do"
    assign check_lt_or_eq = instruction[14];
    assign branch_expect_n = instruction[12];

    localparam R_TYPE    = 7'b0110011;  
    localparam I_TYPE    = 7'b0010011;  
    localparam LOAD      = 7'b0000011;  
    localparam STORE     = 7'b0100011;  
    localparam BRANCH    = 7'b1100011;  
    localparam JAL       = 7'b1101111;  
    localparam JALR      = 7'b1100111;  
    localparam LUI       = 7'b0110111;  
    localparam AUIPC     = 7'b0010111;  

    always @(*) begin
        branch = 0;
        mem_read = 0;
        MemtoReg = 0;
        immALU = 2'b00;
        mem_write = 0;
        ALUSrc = 0;
        regWrite = 0;

        case (instruction[6:0])

            R_TYPE: begin  
                ALUSrc = 0;      
                MemtoReg = 0;   
                regWrite = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b10;   
            end

            I_TYPE: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                regWrite = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b10;   
            end

            LOAD: begin  
                ALUSrc = 1;      
                MemtoReg = 1;    
                regWrite = 1;    
                mem_read = 1;     
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            STORE: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                regWrite = 0;    
                mem_read = 0;
                mem_write = 1;    
                branch = 0;
                immALU = 2'b00;   
            end

            BRANCH: begin  
                ALUSrc = 0;      
                MemtoReg = 0;    
                regWrite = 0;    
                mem_read = 0;
                mem_write = 0;
                branch = 1;      
                immALU = 2'b01;   
            end

            JAL: begin  
                ALUSrc = 0;      
                MemtoReg = 0;    
                regWrite = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;  
            end

            JALR: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                regWrite = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            LUI: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                regWrite = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            AUIPC: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                regWrite = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            default: begin
                branch = 0;
                mem_read = 0;
                MemtoReg = 0;
                immALU = 2'b00;
                mem_write = 0;
                ALUSrc = 0;
                regWrite = 0;
            end
        endcase
    end


    wire [2:0] funct3   = instruction[14:12];
    wire       funct7b5 = instruction[30];   // bit 5 of funct7 

    always @* begin
        i_arith    = 1'b1;
        i_unsigned = 1'b0;
        i_sub      = 1'b0;
        i_opsel    = 3'b000; 

        case (immALU)
            2'b00: begin
                i_opsel = 3'b000;
                i_sub   = 1'b0;
            end

            2'b01: begin
                i_opsel    = 3'b000; 
                i_sub      = 1'b1;   
                i_unsigned = funct3[2]; 
            end

            2'b10: begin
                i_opsel = funct3;
                case (funct3)
                    3'b000: i_sub      = funct7b5; 
                    3'b101: i_sub      = funct7b5; 
                    3'b011: i_unsigned = 1'b1;     
                    default: ; 
                endcase
            end

            default: ; 
        endcase
    end

endmodule