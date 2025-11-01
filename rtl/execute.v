module execute (
    input i_clk, i_rst,
    input [31:0] pc, pc_plus4,
<<<<<<< HEAD
    input branch, imm_alu, i_arith, i_unsigned, i_sub, check_lt_or_eq, branch_expect_n, jump, reg_jump,
    input [2:0] i_opsel,
    input [31:0] reg_out_1, reg_out_2, imm,
    output [31:0] next_pc, alu_result,
    output pc_write_trap
);

    // TODO: Calc pc+imm here. Mux btw pc+imm, imm, alu_out, and output to alu_result.
    // TODO: EX-EX forwarding, pass alu-out, write address, write_en, and if alu_result, mem, imm, or imm+pc, should be written to get from output of reg between ex and mem into ex. Replace ALU input if address is same.
    // TODO: MEM-EX Pass data out from writeback and register write address, and write_en flag back to here. If we are writing to either of our read registers, replace the value with output
=======
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
>>>>>>> mrickel
    wire eq, lt;

    wire [31:0] result;

    wire [31:0] pc_plus_offset;

    assign pc_plus_offset = (jump | (branch & 
        ((check_lt_or_eq) ? (branch_expect_n ^ lt) : (branch_expect_n ^ eq)))) // Check if branch is successful
            ? pc + imm // jal or successful branch
            : pc_plus4; // unsuccessful branch or other instruction;

    assign next_pc = reg_jump
         ? {alu_result[31:1], 1'b0} // jalr
         : pc_plus_offset; // Anything else

<<<<<<< HEAD
    assign pc_write_trap = |next_pc[1:0];

    wire [31:0] i_op2; 
    assign i_op2 = imm_alu 
                    ? imm // Use immediate as 2nd operand for instructions which use it
                    : reg_out_2; // Select register as 2nd operand for all other instructions
    alu iALU1(.i_opsel(i_opsel), .i_sub(i_sub), .i_unsigned(i_unsigned), .i_arith(i_arith),
        .i_op1(reg_out_1), .i_op2(i_op2), .o_result(alu_result), .o_eq(eq), .o_slt(lt));
=======
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

>>>>>>> mrickel
endmodule
