module execute (
    input clk, i_rst,
    input [31:0] pc,
    input branch, // Determines whether we are branching
    input memRead, // Determines if we are reading from memory
    input memWrite, // Determines if we are writing to memory
    input reg_write, // Determines if we are writing to the register file
    input imm_alu, // Determines if we are using an immediate operation
    input i_arith, // Determines if shift right is arithmetic
    input i_unsigned, // Determines if comparison is unsigned
    input i_sub, // Determines if addition subtracts
    input check_lt_or_eq, // Determines if we are checking less than or equal (1) or equal (0)
    input branch_expect_n, // Expected branch outcome (1 = not equal/greater than, 0 = equal/less than)
    input jump, // Determines if we are in a jump instruction
    input is_jalr, // Determines if we are in a 'jalr' jump instruction
    input mem_wb_reg_write_en, // Write Enable from MEM/WB
    input ex_mem_reg_write_en, // Write Enable from EX/MEM
    input [2:0] i_opsel, // Operation selection
    input [31:0] reg_out_1, // R1
    input [31:0] reg_out_2, // R2
    input [31:0] imm, // Immediate
    input [31:0] prev_alu, //Previous ALU output for forwarding
    input [31:0] prev_mem, //Previous memory value for forwarding
    input [4:0] rs1_val, //R1 number
    input [4:0] rs2_val, // R2 number
    input [4:0] ex_mem_dest_addr, // RD value for EX/MEM
    input [4:0] mem_wb_dest_addr, // RD value for MEM/WB
    output [31:0] new_pc, // New PC
    output [31:0] alu_result, // Result
    output o_branch_taken
);
    // Branch code
    wire eq, lt;
    wire [31:0] pc_plus4 = pc + 4;
    wire [31:0] pc_plus_imm = pc + imm;
    wire [31:0] result;

    wire [31:0] pc_plus_offset;
    wire branch_taken;

    assign branch_taken = branch ? 
	    		{i_check_lt_or_eq ? (i_branch_expect_n ^ lt):
	    		(i_branch_expect_n ^ eq)} : 0;

    assign pc_plus_offset = (i_jump | branch_taken) ? 
                    (pc_plus_imm) : (pc_plus4);

    assign o_branch_taken = branch_taken;

    assign new_pc = (is_jalr) ? {alu_result[31:1], 1'b0} : pc_plus_offset;

//Forwarding unit driving forwarding muxes
wire [1:0] fw1, fw2; //Forward controls

assign fw1 =
	(mem_wb_reg_write_en && |ex_mem_dest_addr && (ex_mem_dest_addr == rs1_val)) ? 2'b10: //EX hazard
	(mem_wb_reg_write_en && |mem_wb_dest_addr && !(ex_mem_reg_write_en &&  |ex_mem_dest_addr)) && (ex_mem_dest_addr == rs1_val) &&
	(mem_wb_dest_addr == rs1_val) : 2'b01 : //MEM hazard
	2'b00;	//No hazard

assign fw2 =
	(mem_wb_reg_write_en && |ex_mem_dest_addr && (ex_mem_dest_addr == rs2_val)) ? 2'b10: //EX hazard
	(mem_wb_reg_write_en && |mem_wb_dest_addr && !(ex_mem_reg_write_en && |ex_mem_dest_addr) && (ex_mem_dest_addr == rs2_val) &&
	(mem_wb_dest_addr == rs2_val)) : 2'b01 : //MEM hazard
	2'b00;	//No hazard
// MUX for selecting forwarded R1 and R2 values
wire [31:0] alu_op1, alu_op2; //Inputs

assign alu_op1 = (fw1 == 2'b00) ? reg_out_1:
		(fw1 == 2'b10) ? prev_alu:
		(fw1 == 2'b01) ? prev_mem:
		reg_out_1;

assign alu_op2 = (fw1 == 2'b00) ? reg_out_2:
		(fw1 == 2'b10) ? prev_alu:
		(fw1 == 2'b01) ? prev_mem:
		reg_out_2;

// MUX for selecting R2 or IMM
wire [31:0] immVal; 
assign immVal = (imm_alu) ? imm : alu_op2;

//ALU Instantiation
alu iALU1(.i_opsel(i_opsel), .i_sub(i_sub), .i_unsigned(i_unsigned), .i_arith(i_arith),
	.i_op1(alu_op1), .i_op2(immVal), .o_result(alu_result), .o_seq(eq), .o_slt(lt));

endmodule