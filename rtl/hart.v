`default_nettype none
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

    wire [31:0] next_pc;
    wire [31:0] instruction;
    wire [31:0] pc_plus4;
    wire [31:0] pc;
    wire [31:0] reg_write_data;


    // Intermediate signals between stages
    // Decode outputs
    wire        branch, mem_read, mem_write, reg_write, imm_alu, reg_write_en;
    wire        check_lt_or_eq, branch_expect_n, jump, reg_jump;
    wire        is_word, is_h_or_b, is_unsigned_ld;
    wire        is_auipc, is_lui;
    wire        i_arith, i_unsigned, i_sub;
    wire [2:0]  i_opsel;
    wire [31:0] reg_out_1, reg_out_2, imm;
    wire [4:0]  rd_addr, rs1_addr, rs2_addr;
    wire decode_trap, mem_trap, pc_write_trap;

    wire is_r;
    wire is_i;
    wire is_s;
    wire is_b;
    wire is_u;
    wire is_j;

    // Execute outputs
    wire [31:0] alu_result;
    // Memory outputs
    wire [31:0] mem_data_out;

    // Connect fetch module

    fetch #(.RESET_ADDR(RESET_ADDR)) Fetch(
        .i_clk(i_clk), 
        .i_rst(i_rst), 
        .next_pc(next_pc), 
        .i_imem_rdata(i_imem_rdata), 
        .o_imem_raddr(o_imem_raddr), 
        .instruction(instruction), 
        .pc_plus4(pc_plus4), 
        .pc(pc)
    );

    assign o_retire_inst = instruction;
    assign o_retire_pc = pc;

    decode Decode(
        .i_clk(i_clk), 
        .i_rst(i_rst), 
        .instruction(instruction), 
        .reg_write_data(reg_write_data),
        .rd_addr(rd_addr),
        .pc_plus4(pc_plus4),
        .branch(branch), 
        .mem_read(mem_read), 
        .mem_write(mem_write), 
        .reg_write(reg_write), 
        .imm_alu(imm_alu), 
        .check_lt_or_eq(check_lt_or_eq), 
        .branch_expect_n(branch_expect_n), 
        .jump(jump), 
        .reg_jump(reg_jump), 
        .is_word(is_word), 
        .is_h_or_b(is_h_or_b), 
        .is_unsigned_ld(is_unsigned_ld), 
        .i_arith(i_arith), 
        .i_unsigned(i_unsigned), 
        .i_sub(i_sub),
        .i_opsel(i_opsel),
        .is_auipc(is_auipc),
        .reg_write_en(reg_write_en),
        .is_lui(is_lui),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .imm_out(imm),
        .is_r(is_r),
        .is_i(is_i),
        .is_s(is_s),
        .is_b(is_b),
        .is_u(is_u),
        .is_j(is_j),
        .decode_trap(decode_trap),
        .halt(o_retire_halt)
    );

    rf rf(
        .i_clk       (i_clk),
        .i_rst       (i_rst),
        .i_rs1_raddr (rs1_addr),
        .o_rs1_rdata (reg_out_1),
        .i_rs2_raddr (rs2_addr),
        .o_rs2_rdata (reg_out_2),
        .i_rd_wen    (reg_write_en),
        .i_rd_waddr  (rd_addr),
        .i_rd_wdata  (reg_write_data)
    ); 

    assign o_retire_rs1_raddr = ~(is_u) ? rs1_addr : 5'd0;
    assign o_retire_rs2_raddr = ~(is_i | is_u | is_j) ? rs2_addr : 5'd0;
    assign o_retire_rd_waddr =  ~(is_s | is_b) ? rd_addr : 5'd0;
    assign o_retire_rs1_rdata = ~(is_u) ? reg_out_1 : 32'd0;
    assign o_retire_rs2_rdata = ~(is_i | is_u | is_j) ? reg_out_2 : 32'd0;
    assign o_retire_rd_wdata = ~(is_s | is_b) ? reg_write_data : 32'd0;

    execute Execute(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .reg_out_1(reg_out_1),
        .reg_out_2(reg_out_2),
        .imm(imm),
        .imm_alu(imm_alu),
        .pc(pc),
        .pc_plus4(pc_plus4),
        .i_arith(i_arith),
        .i_unsigned(i_unsigned),
        .i_sub(i_sub),
        .i_opsel(i_opsel),
        .branch(branch),
        .jump(jump),
        .reg_jump(reg_jump),
        .check_lt_or_eq(check_lt_or_eq),
        .branch_expect_n(branch_expect_n),
        .alu_result(alu_result),
        .next_pc(next_pc),
        .pc_write_trap(pc_write_trap)

    );

    memory Memory(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .w_data(reg_out_2),
        .address(alu_result),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .is_word(is_word),
        .is_h_or_b(is_h_or_b),
        .is_unsigned_ld(is_unsigned_ld),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask),
        .mem_data_out(mem_data_out),
        .mem_trap(mem_trap)
    );

    writeback Writeback(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .alu_result(alu_result),
        .mem_data_out(mem_data_out),
        .pc_plus4(pc_plus4),
        .pc(pc),
        .imm(imm),
        .mem_read(mem_read),
        .reg_write(reg_write),
        .is_auipc(is_auipc),
        .is_lui(is_lui),
        .reg_write_data(reg_write_data),
        .reg_write_en(reg_write_en),
        .jump(jump)
    );

    assign o_retire_valid = 1'b1;
    assign o_retire_next_pc = next_pc;
    assign o_retire_trap = pc_write_trap | mem_trap | decode_trap;

endmodule

`default_nettype wire
