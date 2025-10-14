module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // WISC-25 supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this
    // should be 5'd0.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`), this
    // should be 5'd0.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    // Fill in your implementation here.
//////////////////////RF IMPLEMENTATION FOR TESTBENCH////////////////////////
module rf (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_we,
    input  wire [4:0]  i_waddr,
    input  wire [31:0] i_wdata,
    input  wire [4:0]  i_raddr1,
    input  wire [4:0]  i_raddr2,
    output wire [31:0] o_rdata1,
    output wire [31:0] o_rdata2
);
    reg [31:0] mem[0:31];
    integer i;

    // synchronous write, x0 hard-wired to 0, reset clears regs
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (i = 0; i < 32; i = i + 1)
                mem[i] <= 32'b0;
        end else begin
            if (i_we && (i_waddr != 5'd0))
                mem[i_waddr] <= i_wdata;
            mem[0] <= 32'b0;
        end
    end

    // combinational reads; x0 is always 0
    assign o_rdata1 = (i_raddr1 == 5'd0) ? 32'b0 : mem[i_raddr1];
    assign o_rdata2 = (i_raddr2 == 5'd0) ? 32'b0 : mem[i_raddr2];
endmodule
//////////////////////////////////////////////////////////////////////////////

    // =========================
    // PC + Register File
    // =========================
	
    reg [31:0] pc_q, pc_d; //Current and next instructions
    assign o_imem_raddr = pc_q; //To instruction memory
	
    wire       rf_we; //WE for register file 
    wire [4:0] rf_waddr; //register to write
    wire [31:0] rf_wdata; //value to be stored
	wire [31:0] rs1_val, rs2_val; // rs1/rs2 values via the rf submodule
	
// Program Counter register
	always @(posedge i_clk) begin
		if (i_rst) pc_q <= RESET_ADDR;
		else       pc_q <= pc_d;
end

//tb can read dut.rf.mem[10]
	rf rf (.i_clk(i_clk), .i_rst(i_rst), .i_we(rf_we), .i_waddr(rf_waddr), .i_wdata(rf_wdata),
		   .i_raddr1(rs1), .i_raddr2(rs2), .o_rdata1(rs1_val), .o_rdata2(rs2_val));


    // =========================
    // Fetch / Decode fields
    // =========================
	
    wire [31:0] instr  = i_imem_rdata; //fetched from IMEM
    wire [6:0]  opcode = instr[6:0]; 
    wire [2:0]  funct3 = instr[14:12]; //sub-op selector
    wire [6:0]  funct7 = instr[31:25]; //sub-op selector
    wire [4:0]  rs1    = instr[19:15];
    wire [4:0]  rs2    = instr[24:20];
    wire [4:0]  rd     = instr[11:7];

	//Force zero if index=0, else read he register file array
    wire [31:0] rs1_val = (rs1 == 5'd0) ? 32'd0 : x[rs1];
    wire [31:0] rs2_val = (rs2 == 5'd0) ? 32'd0 : x[rs2];

    // Immediates (concat sign-extend)
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]}; //I-type ImmGen
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]}; //S-type ImmGen
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; //B-type ImmGen
    wire [31:0] imm_u = {instr[31:12], 12'b0}; //U-type ImmGen
    wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; //J-type ImmGen

    // Instruction Class 
	//[3.1. Register Arithmetic Instructions]
    wire is_op     = (opcode == 7'b0110011); 
	//[3.2. Register-Immediate Computational Instructions]
    wire is_opimm  = (opcode == 7'b0010011);
	//[3.3. Integer Immediate Instructions]
    wire is_lui    = (opcode == 7'b0110111);
    wire is_auipc  = (opcode == 7'b0010111);
	//[3.4. Conditional Branch Instructions]
    wire is_branch = (opcode == 7'b1100011);
	//[3.5. Unconditional Jumps]
    wire is_jal    = (opcode == 7'b1101111);
    wire is_jalr   = (opcode == 7'b1100111) && (funct3 == 3'b000);
	//[3.6. Memory Instructions]
	wire is_load   = (opcode == 7'b0000011);
    wire is_store  = (opcode == 7'b0100011);
	
    // EBREAK exact: 0x0010_0073
    wire is_system = (opcode == 7'b1110011);
    wire is_ebreak = is_system &&
                     (instr[31:20] == 12'h001) &&
                     (funct3 == 3'b000) && (rs1 == 5'd0) && (rd == 5'd0);
					 
					 
    // =========================
    // ALU implementation
    // =========================
	
	//Named constants for every ALUop.
    localparam ALU_ADD=4'd0, ALU_SUB=4'd1, ALU_SLT=4'd2, ALU_SLTU=4'd3,
               ALU_XOR=4'd4, ALU_OR =4'd5, ALU_AND =4'd6,
               ALU_SLL=4'd7, ALU_SRL=4'd8, ALU_SRA =4'd9, ALU_PASS=4'd15;

    reg [3:0]  alu_op; //selected operand
    reg [31:0] alu_a, alu_b; //operands
    reg [31:0] alu_y; //result

    always @* begin
        // defaults
        alu_a  = rs1_val;
        alu_b  = rs2_val;
        alu_op = ALU_ADD;

	//RISC-V uses funct3 and the bit 30 (func7[5]) of the instruction to distinguish ops:
        if (is_op) begin
            case ({funct7[5],funct3})
                4'b0_000: alu_op = ALU_ADD; 
                4'b1_000: alu_op = ALU_SUB; 
                4'b0_100: alu_op = ALU_XOR;
                4'b0_110: alu_op = ALU_OR;
                4'b0_111: alu_op = ALU_AND;
                4'b0_001: alu_op = ALU_SLL;
                4'b0_101: alu_op = ALU_SRL;
                4'b1_101: alu_op = ALU_SRA;
                4'b0_010: alu_op = ALU_SLT;
                4'b0_011: alu_op = ALU_SLTU;
                default:  alu_op = ALU_ADD;
            endcase
		//Immediate goes in alu_b:
        end
		else if (is_opimm) begin
            case (funct3)
                3'b000: begin alu_op=ALU_ADD;  alu_b=imm_i; end // ADDI
                3'b100: begin alu_op=ALU_XOR;  alu_b=imm_i; end // XORI
                3'b110: begin alu_op=ALU_OR;   alu_b=imm_i; end // ORI
                3'b111: begin alu_op=ALU_AND;  alu_b=imm_i; end // ANDI
                3'b010: begin alu_op=ALU_SLT;  alu_b=imm_i; end // SLTI
                3'b011: begin alu_op=ALU_SLTU; alu_b=imm_i; end // SLTIU
                3'b001: begin alu_op=ALU_SLL;  alu_b={27'b0,instr[24:20]}; end // SLLI
		// SRLI/SRAI - Shifts use the shamt (instr[24:20]), so alu_b = {27'b0, instr[24:20]}.
                3'b101: begin alu_op=(instr[30]?ALU_SRA:ALU_SRL); alu_b={27'b0,instr[24:20]}; end           
                default: begin alu_op=ALU_ADD; alu_b=imm_i; end
            endcase			
        end
		else if (is_load)  	   begin alu_op=ALU_ADD; alu_b=imm_i; end //Loads: rs1 + imm_i
        else if (is_store)     begin alu_op=ALU_ADD; alu_b=imm_s; end //Stores: rs1 + imm_s
        else if (is_auipc)     begin alu_op=ALU_ADD; alu_a=pc_q;  alu_b=imm_u; end //AUIPC: pc + imm_u
        else if (is_lui)       begin alu_op=ALU_PASS; alu_a=imm_u; alu_b=32'd0; end //LUI: just place imm_u in rd
    end
	
	//EXECUTION
    always @* begin
        case (alu_op)
            ALU_ADD:  alu_y = alu_a + alu_b;
            ALU_SUB:  alu_y = alu_a - alu_b;
            ALU_XOR:  alu_y = alu_a ^ alu_b;
            ALU_OR :  alu_y = alu_a | alu_b;
            ALU_AND:  alu_y = alu_a & alu_b;
            ALU_SLL:  alu_y = alu_a <<  alu_b[4:0];
            ALU_SRL:  alu_y = alu_a >>  alu_b[4:0];
            ALU_SRA:  alu_y = $signed(alu_a) >>> alu_b[4:0];
            ALU_SLT:  alu_y = {31'b0, ($signed(alu_a) <  $signed(alu_b))};
            ALU_SLTU: alu_y = {31'b0, (alu_a < alu_b)};
            default:  alu_y = alu_a;
        endcase
    end
	
	
    // =========================
    // Branch / Next PC
    // =========================
	
	//BEQ/BNE use equality.
    wire beq  = (rs1_val == rs2_val);
    wire bne  = (rs1_val != rs2_val);
	//BLT/BGE are signed compares
    wire blt  = ($signed(rs1_val) <  $signed(rs2_val));
    wire bge  = ($signed(rs1_val) >= $signed(rs2_val));
	//BLTU/BGEU are unsigned compares
    wire bltu = (rs1_val <  rs2_val);
    wire bgeu = (rs1_val >= rs2_val);

	//Branch to respective operations
    reg take_branch;
    always @* begin
        take_branch = 1'b0;
        if (is_branch) begin
            case (funct3)
                3'b000: take_branch = beq;
                3'b001: take_branch = bne;
                3'b100: take_branch = blt;
                3'b101: take_branch = bge;
                3'b110: take_branch = bltu;
                3'b111: take_branch = bgeu;
                default: take_branch = 1'b0;
            endcase
        end
    end

    wire [31:0] pc_plus4 = pc_q + 32'd4; //increment PC
    wire [31:0] jal_tgt  = pc_q + imm_j; //JAL target
    wire [31:0] br_tgt   = pc_q + imm_b; //branch target
    wire [31:0] jalr_tgt = { (rs1_val + imm_i)[31:1], 1'b0 }; //JALR target

	//PC MUX PRIORITY: JAL -> JALR -> default -> PC_INCREMENT
    wire [31:0] next_pc_comb =
        is_jal  ? jal_tgt  :
        is_jalr ? jalr_tgt :
        take_branch ? br_tgt : pc_plus4;


    // =========================
    // DMEM (mask/address generation)
    // =========================
// Calculates the effective data memory address for loads/stores (rs1 + imm).
// Generates the o_dmem_mask for byte/halfword/word accesses, and aligns store data into the correct byte lanes for writes.
	
	
    // =========================
    // Writeback
    // =========================
// Selects the final value to write back into the register file.
// For loads, uses the memory read data (sign/zero-extended).
// For ALU/jump/upper-immediate ops, uses ALU or PC-related results.


    // =========================
    // Trap & Halt
    // =========================
// Detects illegal or misaligned accesses and sets trap signals.
// Also checks for EBREAK instructions that halt the CPU (to stop simulation).


    // =========================
    // PC update
    // =========================
// Chooses the next PC value each cycle.
// Normally increments by 4, but jumps to branch/jump targets, or stays constant on halt (EBREAK).

	
	// =========================
    // Outputs
    // =========================
// Drives the retirement interface for the testbench.
// Reports the current instruction, register read/write data, PC values, and any trap/halt conditions once an instruction completes.


endmodule

`default_nettype wire
