module execute (
    input i_clk, i_rst,
    input [31:0] pc,
    input branch, // Determines whether we are branching
    input imm_alu, // Determines if we are using an immediate operation
    input i_arith, // Determines if shift right is arithmetic
    input i_unsigned, // Determines if comparison is unsigned
    input i_sub, // Determines if addition subtracts
    input check_lt_or_eq, // Determines if we are checking less than or equal (1) or equal (0)
    input branch_expect_n, // Expected branch outcome (1 = not equal/greater than, 0 = equal/less than)
    input jump, // Determines if we are in a jump instruction
    input is_jalr, // Determines if we are in a 'jalr' jump instruction
    input is_lui, // Determines if we are in a LUI instruction
    input is_auipc, // Determines if we are in an AUIPC instruction
    input mem_wb_reg_write_en, // Write Enable from MEM/WB
    input ex_mem_reg_write_en, // Write Enable from EX/MEM
    input [2:0] i_opsel, // Operation selection
    input [31:0] reg_out_1, // R1
    input [31:0] reg_out_2, // R2
    input [31:0] imm, // Immediate
    input [31:0] ex_mem_data, //Previous ALU output for forwarding
    input [31:0] mem_wb_data, //Previous memory value for forwarding
    input wire rs1_used, rs2_used, // Whether rs1 and rs2 are used
    input [4:0] rs1_addr, //R1 number
    input [4:0] rs2_addr, // R2 number
    input [4:0] ex_mem_dest_addr, // RD value for EX/MEM
    input [4:0] mem_wb_dest_addr, // RD value for MEM/WB
    output wire [31:0] o_rs1_fwd_data, o_rs2_fwd_data, // Forwarded data outputs for retire
    output wire pc_write_trap,
    output [31:0] new_pc, // New PC
    output [31:0] ex_data_out, // Result
    output o_branch_taken
);
    // Branch code
    wire eq, lt;
    wire [31:0] pc_plus4 = pc + 4;
    wire [31:0] pc_plus_imm = pc + imm;
    wire [31:0] result;

    wire [31:0] pc_plus_offset;

    wire [31:0] alu_op1, alu_op2;
    wire branch_taken;
    wire rs1_ex_fwd, rs2_ex_fwd, rs1_mem_fwd, rs2_mem_fwd;

    assign branch_taken = branch ? 
	    		{check_lt_or_eq ? (branch_expect_n ^ lt):
	    		(branch_expect_n ^ eq)} : 0;

    assign pc_plus_offset = (jump | branch_taken) ? 
                    (pc_plus_imm) : (pc_plus4);

    assign o_branch_taken = branch_taken | jump;

    assign new_pc = (is_jalr) ? {ex_data_out[31:1], 1'b0} : pc_plus_offset;

    assign pc_write_trap = |new_pc[1:0];

    assign rs1_ex_fwd = rs1_used && ex_mem_reg_write_en && |ex_mem_dest_addr && (ex_mem_dest_addr == rs1_addr);
    assign rs2_ex_fwd = rs2_used && ex_mem_reg_write_en && |ex_mem_dest_addr && (ex_mem_dest_addr == rs2_addr);
    assign rs1_mem_fwd = rs1_used && mem_wb_reg_write_en && |mem_wb_dest_addr && (mem_wb_dest_addr == rs1_addr);
    assign rs2_mem_fwd = rs2_used && mem_wb_reg_write_en && |mem_wb_dest_addr && (mem_wb_dest_addr == rs2_addr);

    assign alu_op1 =
        (rs1_ex_fwd) ? ex_mem_data : //EX hazard
        (rs1_mem_fwd) ? mem_wb_data : //MEM hazard
        reg_out_1;	//No hazard

    assign alu_op2 = imm_alu ? imm : // Immediate operation
        (rs2_ex_fwd) ? ex_mem_data : //EX hazard
        (rs2_mem_fwd) ? mem_wb_data : //MEM hazard
        reg_out_2;	//No hazard

    assign o_rs1_fwd_data = alu_op1;
    assign o_rs2_fwd_data = alu_op2;

    //ALU Instantiation
    alu iALU1(.i_opsel(i_opsel), .i_sub(i_sub), .i_unsigned(i_unsigned), .i_arith(i_arith),
        .i_op1(alu_op1), .i_op2(alu_op2), .o_result(result), .o_eq(eq), .o_slt(lt));

    // Output mux
    assign ex_data_out = jump ? pc_plus4 : is_lui ? imm : is_auipc ? pc_plus_imm : result;

endmodule