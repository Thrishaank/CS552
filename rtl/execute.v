module execute (
    input clk, i_rst,
    input [31:0] pc, pc_plus4,
    input branch, //Determines whether we are branching
    memRead, //Determines if we are reading from memory
    memWrite, //Determines if we are writing to memory
    reg_write, //Determines if we are writing to the register file
    imm_alu, //Determines if we are using an immediate operation
    i_arith, //Determines if shift right is arithmetic
    i_unsigned, //Determines if comparison is unsigned
    i_sub, //Determines if addition subtracts
    check_lt_or_eq, 
    branch_expect_n,
    jump, //Determines if we are in a jump instruction
    reg_jump, //Determines if we are in a 'jalr' jump instruction
    memwb_rw, //RW value from MEM/WB
    exmem_rw, //RW value from EX/MEM
    input [2:0] i_opsel, //Operation selection
    input [31:0] reg_out_1, //R1
    reg_out_2, //R2
    imm, //Immediate
    prev_alu, //Previous ALU output for forwarding
    prev_mem, //Previous memory value for forwarding
    input [4:0] rs1_val, //R1 number
    rs2_val, //R2 number
    exmem_rd, //RD value for EX/MEM
    memwb_rd, //RD value for MEM/WB
    output [31:0] new_pc, //New PC
    alu_result //Result
);
//Branch code
    wire eq, lt;

    wire [31:0] result;

    wire pc_plus_offset;

    assign pc_plus_offset = (jump | (branch & ((check_lt_or_eq) ? 
                        (branch_expect_n ^ lt) : (branch_expect_n ^ eq)))) ? 
                    (pc + imm) : (pc_plus4);

    assign new_pc = (reg_jump) ? {alu_result[31:1], 1'b0} : pc_plus_offset;

//Forwarding unit driving forwarding muxes
wire [1:0] fw1, fw2; //Forward controls
assign fw1 =
	(memwb_rw && (exmem_rd != 0) && (exmem_rd == rs1_val)) ? 2'b10: //EX hazard
	(memwb_rw && (memwb_rd != 0) && !(exmem_rw &&  (exmem_rd != 0)) && (exmem_rd == rs1_val) &&
	(memwb_rd == rs1_val) : 2'b01 : //MEM hazard
	2'b00;	//No hazard

assign fw2 =
	(memwb_rw && (exmem_rd != 0) && (exmem_rd == rs2_val)) ? 2'b10: //EX hazard
	(memwb_rw && (memwb_rd != 0) && !(exmem_rw && (exmem_rd != 0)) && (exmem_rd == rs2_val) &&
	(memwb_rd == rs2_val) : 2'b01 : //MEM hazard
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
