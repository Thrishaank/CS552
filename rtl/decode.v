module decode(
    input clk, i_rst,
    input [31:0] instruction,
    input [31:0] reg_write_data,
    input [31:0] pc_plus4,
    output branch, mem_read, mem_write, regWrite, immALU, check_lt_or_eq, branch_expect_n, jump, reg_jump, is_word, is_h_or_b, is_unsigned_ld, 
    output i_arith, i_unsigned, i_sub,
    output [2:0] i_opsel,
    output [31:0] reg_out_1, reg_out_2, imm_out
);

    //  i_rs1_raddr = instruction[19:15];
    //  i_rs2_raddr = instruction[24:20];
    //  i_rd_waddr = instruction[11:7];
    //  i_inst = instruction;

    //2'b00 - "Just do ADD for address calculation"
    //2'b01 - "Just do SUB for comparison"
    //2'b10 - "Look at funct3/funct7 to decide what to do"


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
        reg_write = 0;

        case (instruction[6:0])

            R_TYPE: begin  
                ALUSrc = 0;      
                MemtoReg = 0;   
                reg_write = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b10;   
            end

            I_TYPE: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                reg_write = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b10;   
            end

            LOAD: begin  
                ALUSrc = 1;      
                MemtoReg = 1;    
                reg_write = 1;    
                mem_read = 1;     
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            STORE: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                reg_write = 0;    
                mem_read = 0;
                mem_write = 1;    
                branch = 0;
                immALU = 2'b00;   
            end

            BRANCH: begin  
                ALUSrc = 0;      
                MemtoReg = 0;    
                reg_write = 0;    
                mem_read = 0;
                mem_write = 0;
                branch = 1;      
                immALU = 2'b01;   
            end

            JAL: begin  
                ALUSrc = 0;      
                MemtoReg = 0;    
                reg_write = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;  
            end

            JALR: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                reg_write = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            LUI: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                reg_write = 1;    
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                immALU = 2'b00;   
            end

            AUIPC: begin  
                ALUSrc = 1;      
                MemtoReg = 0;    
                reg_write = 1;    
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
                reg_write = 0;
            end
        endcase
    end

    assign check_lt_or_eq = instruction[14];
    assign branch_expect_n = instruction[12];

endmodule