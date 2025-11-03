module execute (
    input clk, i_rst,
    input [31:0] pc, //pc_plus4,
    input branch, //Determines whether we attempt to branch
    i_mem_read, //Determines if we are reading from memory
    i_mem_write, //Determines if we are writing to memory
    i_reg_write, //Determines if we are writing to the register file
    i_i_imm_alu, //Determines if we are using an immediate operation
    i_arith, //Determines if shift right is arithmetic
    i_unsigned, //Determines if comparison is unsigned
    i_sub, //Determines if addition subtracts
    i_check_lt_or_eq, 
    i_branch_expect_n,
    i_jump, //Determines if we are in a i_jump instruction
    i_reg_i_jump, //Determines if we are in a 'jalr' i_jump instruction
    i_mem_reg_write, //RW value from MEM/WB
    i_ex_reg_write, //RW value from EX/MEM
    i_is_auipc,
    i_is_lui,
    input [2:0] i_opsel, //Operation selection
    input [31:0] i_reg_out_1, //R1
    i_reg_out_2, //R2
    imm, //Immediate
    prev_alu, //Previous ALU output for forwarding
    prev_mem, //Previous memory value for forwarding
    input [4:0] i_rs1_val, //R1 number
    i_rs2_val, //R2 number
    i_ex_rd_addr, //RD value for EX/MEM
    i_mem_rd_addr, //RD value for MEM/WB
    output [31:0] o_new_pc, //New PC
    o_ex_result, //Result
    output
    o_branch_taken, //Signals if branch is taken
    o_flush_pipeline //Flush IF/ID and ID/EX registers on control flow change
);
//Branch code
    wire [31:0] pc_plus4 = pc + 4;
    wire [31:0] pc_plus_imm = pc + imm;
    wire eq, lt; //Assigned by the ALU instantiated later

    wire pc_plus_offset;

    assign o_branch_taken = branch ? 
	    		{i_check_lt_or_eq ? (i_branch_expect_n ^ lt):
	    		(i_branch_expect_n ^ eq)} : 0;

    // Flush pipeline when control flow changes (branch taken or any jump)
    // This implements the always-not-taken branch predictor recovery
    assign o_flush_pipeline = o_branch_taken | i_jump;

    assign pc_plus_offset = (i_jump | o_branch_taken) ? 
                    (pc_plus_imm) : (pc_plus4);

    assign o_new_pc = (i_reg_i_jump) ? {alu_result[31:1], 1'b0} : pc_plus_offset;

//Forwarding unit driving forwarding muxes
wire [1:0] fw1, fw2; //Forward controls
assign fw1 =
	(i_mem_reg_write && (i_ex_rd_addr != 0) && (i_ex_rd_addr == i_rs1_val)) ? 2'b10: //EX hazard
	(i_mem_reg_write && (i_mem_rd_addr != 0) && !(i_ex_reg_write &&  (i_ex_rd_addr != 0)) && (i_ex_rd_addr == i_rs1_val) &&
	(i_mem_rd_addr == i_rs1_val) : 2'b01 : //MEM hazard
	2'b00;	//No hazard

assign fw2 =
	(i_mem_reg_write && (i_ex_rd_addr != 0) && (i_ex_rd_addr == i_rs2_val)) ? 2'b10: //EX hazard
	(i_mem_reg_write && (i_mem_rd_addr != 0) && !(i_ex_reg_write && (i_ex_rd_addr != 0)) && (i_ex_rd_addr == i_rs2_val) &&
	(i_mem_rd_addr == i_rs2_val) : 2'b01 : //MEM hazard
	2'b00;	//No hazard
// MUX for selecting forwarded R1 and R2 values
wire [31:0] alu_op1, alu_op2; //Inputs

assign alu_op1 = (fw1 == 2'b00) ? i_reg_out_1:
		(fw1 == 2'b10) ? prev_alu:
		(fw1 == 2'b01) ? prev_mem:
		i_reg_out_1;

assign alu_op2 = (fw2 == 2'b00) ? i_reg_out_2:
		(fw2 == 2'b10) ? prev_alu:
		(fw2 == 2'b01) ? prev_mem:
		i_reg_out_2;

// MUX for selecting R2 or IMM
wire [31:0] immVal; 
assign immVal = (i_i_imm_alu) ? imm : alu_op2;

//ALU Instantiation
wire [31:0] alu_result;
alu iALU1(.i_opsel(i_opsel), .i_sub(i_sub), .i_unsigned(i_unsigned), .i_arith(i_arith),
	.i_op1(alu_op1), .i_op2(immVal), .o_result(alu_result), .o_seq(eq), .o_slt(lt));
assign o_ex_result = 
	(is_i_jump) ? pc_plus4:
	(is_lui) ? imm:
	(is_auipc) ? pc_plus_imm:
	alu_result;

endmodule