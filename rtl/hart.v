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
    input  wire        i_imem_ready,
    output wire [31:0] o_imem_raddr,
    output wire        o_imem_ren,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire        i_imem_valid,
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
    input  wire        i_dmem_ready,
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
    // `0x00002003`, assert `o_dmem_wen`, and set the mask to 0b1000 to
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
    input  wire        i_dmem_valid,
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
    output wire [31:0] o_retire_dmem_addr,
    output wire [ 3:0] o_retire_dmem_mask,
    output wire        o_retire_dmem_ren,
    output wire        o_retire_dmem_wen,
    output wire [31:0] o_retire_dmem_rdata,
    output wire [31:0] o_retire_dmem_wdata,
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
    // Internal wires and registers.
    wire [31:0] instruction_ex, instruction_mem, instruction_wb;
    wire [31:0] pc_if, pc_id, pc_ex, pc_mem, pc_wb;
    wire [31:0] new_pc_ex, new_pc_mem, new_pc_wb;
    wire rs1_used_id, rs1_used_ex, rs1_used_mem, rs1_used_wb;
    wire rs2_used_id, rs2_used_ex, rs2_used_mem, rs2_used_wb;
    wire [4:0] rs1_addr_id, rs1_addr_ex, rs1_addr_mem, rs1_addr_wb;
    wire [4:0] rs2_addr_id, rs2_addr_ex, rs2_addr_mem, rs2_addr_wb;
    wire [4:0] rd_addr_id, rd_addr_ex, rd_addr_mem, rd_addr_wb;
    wire [31:0] reg_out_1_id, reg_out_1_ex, reg_out_1_mem, reg_out_1_wb;
    wire [31:0] reg_out_2_id, reg_out_2_ex, reg_out_2_mem, reg_out_2_wb;
    wire [31:0] imm_id;
    wire [31:0] imm_ex;
    wire branch_taken;
    wire stall, prev_stall;
    wire stall_from_decode;
    
    // Cache wiring
    wire icache_busy, dcache_busy;
    reg [31:0] icache_addr; 
    wire [31:0] icache_rdata;
    wire [31:0]fetch_addr;
    reg [31:0] prev_addr;
    wire icache_ren;
    wire [31:0] dcache_addr_int, dcache_rdata;
    wire dcache_ren_int, dcache_wen_int;
    wire [31:0] dcache_wdata_int;
    wire [3:0] dcache_mask_int, dmem_mask_wb;
    
    // Memory interface from caches
    wire icache_mem_ren, dcache_mem_ren;
    wire icache_mem_wen, dcache_mem_wen;
    wire [31:0] icache_mem_addr;
    wire [31:0] icache_mem_wdata, dcache_mem_wdata;
    
    wire valid_if, valid_id, valid_ex, valid_mem, valid_wb;
    wire prev_valid_if;
    wire [31:0] reg_write_data_wb, dmem_wdata_wb;
    wire pc_write_trap, mem_trap, decode_trap;
    wire trap_ex, trap_mem, trap_wb;
    wire branch_id, branch_ex;
    wire jump_id, jump_ex;
    wire is_jalr_id, is_jalr_ex;
    wire check_lt_or_eq_id, check_lt_or_eq_ex;
    wire branch_expect_n_id, branch_expect_n_ex;
    wire i_arith_id, i_arith_ex;
    wire i_unsigned_id, i_unsigned_ex;
    wire i_sub_id, i_sub_ex;
    wire [2:0] i_opsel_id, i_opsel_ex;
    wire is_auipc_id, is_auipc_ex;
    wire is_lui_id, is_lui_ex;
    wire halt_id, halt_ex, halt_mem, halt_wb;
    wire imm_alu_id, imm_alu_ex;
    wire mem_read_id, mem_read_ex, mem_read_mem, mem_read_wb;
    wire mem_write_id, mem_write_ex, mem_write_mem;
    wire is_word_id, is_word_ex, is_word_mem, is_word_wb;
    wire is_h_or_b_id, is_h_or_b_ex, is_h_or_b_mem, is_h_or_b_wb;
    wire is_unsigned_ld_id, is_unsigned_ld_ex, is_unsigned_ld_mem, is_unsigned_ld_wb;
    wire reg_write_en_id, reg_write_en_ex, reg_write_en_mem, reg_write_en_wb;
    wire [31:0] ex_data_out_ex, ex_data_out_mem, ex_data_out_wb;
    wire [31:0] mem_data_out_wb, dmem_addr_wb;
    wire [31:0] rs1_fwd_data, rs2_fwd_data;

    wire [31:0] instruction_in;
    reg [31:0] prev_instruction;
    wire use_icache_rdata;
    reg prev_icache_busy;
    reg first_instruction;
    wire instr_in_valid;

    reg valid_cache;
    reg prev_dcache_busy, reg_write_en_cache;

    reg [31:0] prev_req_addr, prev_req_wdata;
    reg [3:0] prev_req_mask;

    reg dcache_miss;

    assign stall = stall_from_decode | icache_busy | dcache_busy | i_rst | dcache_miss;

    localparam NOP = 32'h00000013; // NOP instruction (addi x0, x0, 0)

    d_ff #(.WIDTH(1), .RST_VAL(1'b0)) use_icache_rdata_dff (
        .i_clk(i_clk),
        .i_rst(i_rst | branch_taken),
        .d(1'b1),
        .q(use_icache_rdata)
    );

    d_ff #(.RST_VAL(1'b1)) prev_stall_dff(
        .i_clk(i_clk),
        .i_rst(i_rst | branch_taken),
        .d(stall),
        .q(prev_stall)
    );

    always @(negedge icache_busy, posedge i_rst) begin
        if (i_rst) begin
            first_instruction <= 1'b1;
        end else begin
            first_instruction <= 1'b0;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            prev_icache_busy <= 1'b0;
        end else begin
            prev_icache_busy <= icache_busy;
        end
    end

    // always @(posedge i_clk) begin
    //     if (i_rst | first_instruction) begin
    //         instruction_in <= NOP;
    //     end else if (!icache_busy) begin
    //         instruction_in <= icache_rdata;
    //     end
    // end

    always @(posedge i_clk) begin
        if (i_rst | branch_taken) begin
            prev_instruction <= NOP;
        end else begin
            prev_instruction <= instruction_in;
        end
    end

    // Connect fetch module
    fetch #(.RESET_ADDR(RESET_ADDR)) Fetch(
        .i_clk(i_clk), 
        .i_rst(i_rst), 
        .new_pc(new_pc_ex), 
        .stall(stall),
        .branch_taken(branch_taken),
        .o_imem_raddr(fetch_addr), 
        .pc(pc_if),
        .valid(valid_if)
    );

    /*
    always @(posedge i_clk) begin
        if (i_rst) begin
            prev_addr <= RESET_ADDR;
        end else if (!stall) begin
            prev_addr <= fetch_addr;
        end
    end
    */

    assign icache_ren = ~stall & ~i_rst & ~branch_taken;
    // assign icache_addr = stall ? prev_addr : fetch_addr;

    always @(posedge i_clk) begin
        if (i_rst) begin
            icache_addr <= RESET_ADDR;
        end else if (!stall) begin
            icache_addr <= fetch_addr;
        end
    end
        
    // Instruction cache
    cache icache (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_req_ren(icache_ren),
        .i_req_wen(1'b0),
        .i_req_addr(icache_addr),
        .i_req_wdata(32'h0),
        .i_req_mask(4'hF),
        .o_res_rdata(icache_rdata),
        .o_busy(icache_busy),
        .o_mem_ren(o_imem_ren),
        .o_mem_wen(), // Instruction cache never writes
        .o_mem_addr(o_imem_raddr),
        .o_mem_wdata(), // Instruction cache never writes
        .i_mem_rdata(i_imem_rdata),
        .i_mem_valid(i_imem_valid),
        .i_mem_ready(i_imem_ready)
    );

    assign instruction_in = stall ? prev_instruction : (use_icache_rdata ? icache_rdata : NOP); // NOP
    assign instr_in_valid = stall ? 1'b0 : (use_icache_rdata ? 1'b1 : 1'b0);
    assign pc_id = stall ? 32'b0 : (use_icache_rdata ? icache_addr : 32'b0);

    if_id_reg IF_ID_Reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_stall(stall),
        .i_flush(branch_taken),
        .i_pc(pc_if),
        .o_pc(),
        .i_valid(valid_if),
        .o_valid(prev_valid_if)
    );

    decode Decode(
        .i_clk(i_clk), 
        .i_rst(i_rst), 
        .instruction(instruction_in), 
        .flush_decode(branch_taken),
        .mem_rd_addr(rd_addr_mem),
        .rd_addr(rd_addr_id),
        .branch(branch_id), 
        .ex_mem_read(mem_read_ex),
        .ex_rd_addr(rd_addr_ex),
        .mem_read(mem_read_id), 
        .mem_write(mem_write_id), 
        .reg_write_en(reg_write_en_id), 
        .imm_alu(imm_alu_id), 
        .check_lt_or_eq(check_lt_or_eq_id), 
        .branch_expect_n(branch_expect_n_id), 
        .jump(jump_id), 
        .is_jalr(is_jalr_id), 
        .is_word(is_word_id), 
        .is_h_or_b(is_h_or_b_id), 
        .is_unsigned_ld(is_unsigned_ld_id), 
        .i_arith(i_arith_id), 
        .i_unsigned(i_unsigned_id), 
        .i_sub(i_sub_id),
        .i_opsel(i_opsel_id),
        .is_auipc(is_auipc_id),
        .is_lui(is_lui_id),
        .rs1_addr(rs1_addr_id),
        .rs2_addr(rs2_addr_id),
        .rs1_used(rs1_used_id),
        .rs2_used(rs2_used_id),
        .imm_out(imm_id),
        .decode_trap(decode_trap),
        .halt(halt_id),
        .stall_pipeline(stall_from_decode),
        .prev_valid(instr_in_valid),
        .valid(valid_id)
    );

    rf #(.BYPASS_EN(1)) rf(
        .i_clk       (i_clk),
        .i_rst       (i_rst),
        .i_rs1_raddr (rs1_addr_id),
        .o_rs1_rdata (reg_out_1_id),
        .i_rs2_raddr (rs2_addr_id),
        .o_rs2_rdata (reg_out_2_id),
        .i_rd_wen    ((!dcache_busy & prev_dcache_busy) ? reg_write_en_cache : reg_write_en_wb),
        .i_rd_waddr  (rd_addr_wb),
        .i_rd_wdata  (reg_write_data_wb)
    );

    id_ex_reg ID_EX_Reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .stall_thru(dcache_busy | dcache_miss),
        .stall_kill(icache_busy | stall_from_decode ),
        .i_flush(branch_taken),
        .i_reg_out_1(reg_out_1_id),
        .o_reg_out_1(reg_out_1_ex),
        .i_reg_out_2(reg_out_2_id),
        .o_reg_out_2(reg_out_2_ex),
        .i_rs1_used(rs1_used_id),
        .o_rs1_used(rs1_used_ex),
        .i_rs2_used(rs2_used_id),
        .o_rs2_used(rs2_used_ex),
        .i_imm(imm_id),
        .o_imm(imm_ex),
        .i_pc(pc_id),
        .o_pc(pc_ex),
        .i_i_arith(i_arith_id),
        .o_i_arith(i_arith_ex),
        .i_i_unsigned(i_unsigned_id),
        .o_i_unsigned(i_unsigned_ex),
        .i_i_sub(i_sub_id),
        .o_i_sub(i_sub_ex),
        .i_i_opsel(i_opsel_id),
        .o_i_opsel(i_opsel_ex),
        .i_branch(branch_id),
        .o_branch(branch_ex),
        .i_jump(jump_id),
        .o_jump(jump_ex),
        .i_is_jalr(is_jalr_id),
        .o_is_jalr(is_jalr_ex),
        .i_check_lt_or_eq(check_lt_or_eq_id),
        .o_check_lt_or_eq(check_lt_or_eq_ex),
        .i_branch_expect_n(branch_expect_n_id),
        .o_branch_expect_n(branch_expect_n_ex),
        .i_mem_read(mem_read_id),
        .o_mem_read(mem_read_ex),
        .i_mem_write(mem_write_id),
        .o_mem_write(mem_write_ex),
        .i_is_word(is_word_id),
        .o_is_word(is_word_ex),
        .i_is_h_or_b(is_h_or_b_id),
        .o_is_h_or_b(is_h_or_b_ex),
        .i_is_unsigned_ld(is_unsigned_ld_id),
        .o_is_unsigned_ld(is_unsigned_ld_ex),
        .i_reg_write_en(reg_write_en_id),
        .o_reg_write_en(reg_write_en_ex),
        .i_rd_addr(rd_addr_id),
        .o_rd_addr(rd_addr_ex),
        .i_rs1_addr(rs1_addr_id),
        .o_rs1_addr(rs1_addr_ex),
        .i_rs2_addr(rs2_addr_id),
        .o_rs2_addr(rs2_addr_ex),
        .i_halt(halt_id),
        .o_halt(halt_ex),
        .i_valid(valid_id),
        .o_valid(valid_ex),
        .i_instruction(instruction_in),
        .o_instruction(instruction_ex),
        .i_is_auipc(is_auipc_id),
        .o_is_auipc(is_auipc_ex),
        .i_is_lui(is_lui_id),
        .o_is_lui(is_lui_ex),
        .i_imm_alu(imm_alu_id),
        .o_imm_alu(imm_alu_ex),
        .i_trap(decode_trap),
        .o_trap(trap_ex)
    );

    execute Execute(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .reg_out_1(reg_out_1_ex),
        .reg_out_2(reg_out_2_ex),
        .imm(imm_ex),
        .imm_alu(imm_alu_ex),
        .pc(pc_ex),
        .i_arith(i_arith_ex),
        .i_unsigned(i_unsigned_ex),
        .i_sub(i_sub_ex),
        .i_opsel(i_opsel_ex),
        .branch(branch_ex),
        .jump(jump_ex),
        .is_jalr(is_jalr_ex),
        .is_lui(is_lui_ex),
        .is_auipc(is_auipc_ex),
        .check_lt_or_eq(check_lt_or_eq_ex),
        .branch_expect_n(branch_expect_n_ex),
        .ex_data_out(ex_data_out_ex),
        .new_pc(new_pc_ex),
        .pc_write_trap(pc_write_trap),
        .o_branch_taken(branch_taken),
        .ex_mem_reg_write_en(reg_write_en_mem),
        .ex_mem_dest_addr(rd_addr_mem),
        .ex_mem_data(ex_data_out_mem),
        .mem_wb_reg_write_en(reg_write_en_wb),
        .mem_wb_dest_addr(rd_addr_wb),
        .mem_wb_data(reg_write_data_wb),
        .rs1_addr(rs1_addr_ex),
        .rs2_addr(rs2_addr_ex),
        .rs1_used(rs1_used_ex),
        .rs2_used(rs2_used_ex),
        .o_rs1_fwd_data(rs1_fwd_data),
        .o_rs2_fwd_data(rs2_fwd_data),
        .valid(valid_ex)
    );

    ex_mem_reg EX_MEM_Reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .stall_thru(dcache_busy | dcache_miss),
        .stall_kill(1'b0),
        .i_pc(pc_ex),
        .o_pc(pc_mem),
        .i_new_pc(new_pc_ex),
        .o_new_pc(new_pc_mem),
        .i_reg_out_1(rs1_fwd_data),
        .o_reg_out_1(reg_out_1_mem),
        .i_reg_out_2(rs2_fwd_data),
        .o_reg_out_2(reg_out_2_mem),
        .i_mem_read(mem_read_ex),
        .o_mem_read(mem_read_mem),
        .i_mem_write(mem_write_ex),
        .o_mem_write(mem_write_mem),
        .i_is_word(is_word_ex),
        .o_is_word(is_word_mem),
        .i_is_h_or_b(is_h_or_b_ex),
        .o_is_h_or_b(is_h_or_b_mem),
        .i_is_unsigned_ld(is_unsigned_ld_ex),
        .o_is_unsigned_ld(is_unsigned_ld_mem),
        .i_reg_write_en(reg_write_en_ex),
        .o_reg_write_en(reg_write_en_mem),
        .i_rs1_addr(rs1_addr_ex),
        .o_rs1_addr(rs1_addr_mem),
        .i_rs2_addr(rs2_addr_ex),
        .o_rs2_addr(rs2_addr_mem),
        .i_rs1_used(rs1_used_ex),
        .o_rs1_used(rs1_used_mem),
        .i_rs2_used(rs2_used_ex),
        .o_rs2_used(rs2_used_mem),
        .i_rd_addr(rd_addr_ex),
        .o_rd_addr(rd_addr_mem),
        .i_ex_data_out(ex_data_out_ex),
        .o_ex_data_out(ex_data_out_mem),
        .i_halt(halt_ex),
        .o_halt(halt_mem),
        .i_valid(valid_ex),
        .o_valid(valid_mem),
        .i_instruction(instruction_ex),
        .o_instruction(instruction_mem),
        .i_trap(trap_ex | pc_write_trap),
        .o_trap(trap_mem)
    );

    memory_sub Memory(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .w_data(reg_out_2_mem),
        .address(ex_data_out_mem),
        .mem_read(mem_read_mem),
        .mem_write(mem_write_mem),
        .is_word(is_word_mem),
        .is_h_or_b(is_h_or_b_mem),
        .is_unsigned_ld(is_unsigned_ld_mem),
        .i_dmem_rdata(dcache_rdata),
        .o_dmem_addr(dcache_addr_int),
        .o_dmem_ren(dcache_ren_int),
        .o_dmem_wen(dcache_wen_int),
        .o_dmem_wdata(dcache_wdata_int),
        .o_dmem_mask(dcache_mask_int),
        .mem_trap(mem_trap)
    );
    
    // Data cache
    cache dcache (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_req_ren(dcache_busy ? 1'b0 : dcache_ren_int),
        .i_req_wen(dcache_busy ? 1'b0 : dcache_wen_int),
        .i_req_addr((dcache_miss) ? prev_req_addr : dcache_addr_int),
        .i_req_wdata((dcache_miss) ? prev_req_wdata : dcache_wdata_int),
        .i_req_mask((dcache_miss) ? prev_req_mask : dcache_mask_int),
        .o_res_rdata(dcache_rdata),
        .o_busy(dcache_busy),
        .o_mem_ren(o_dmem_ren),
        .o_mem_wen(o_dmem_wen),
        .o_mem_addr(o_dmem_addr),
        .o_mem_wdata(o_dmem_wdata),
        .i_mem_rdata(i_dmem_rdata),
        .i_mem_valid(i_dmem_valid),
        .i_mem_ready(i_dmem_ready)
    );

    always @(posedge i_clk) begin
        if (i_rst) begin
            prev_req_addr <= 32'd0;
        end else if (!dcache_busy) begin
            prev_req_addr <= dcache_addr_int;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            prev_req_wdata <= 32'd0;
        end else if (!dcache_busy) begin
            prev_req_wdata <= dcache_wdata_int;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            prev_req_mask <= 4'd0;
        end else if (!dcache_busy) begin
            prev_req_mask <= dcache_mask_int;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            valid_cache <= 1'b0;
        end else if (!dcache_busy) begin
            valid_cache <= valid_mem;
        end
    end

    
    always @(posedge i_clk) begin
        if (i_rst) begin
            reg_write_en_cache <= 1'b0;
        end else if (!dcache_busy) begin
            reg_write_en_cache <= reg_write_en_mem;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            prev_dcache_busy <= 1'b0;
        end else begin
            prev_dcache_busy <= dcache_busy;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            dcache_miss <= 1'b0;
        end else if (dcache_busy & !prev_dcache_busy) begin
            dcache_miss <= 1'b1;
        end else if (!dcache_busy & prev_dcache_busy) begin
            dcache_miss <= 1'b0;
        end
    end

    mem_wb_reg MEM_WB_Reg(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .stall_thru(1'b0),
        .stall_kill(dcache_busy),
        .i_pc(pc_mem),
        .o_pc(pc_wb),
        .i_new_pc(new_pc_mem),
        .o_new_pc(new_pc_wb),
        .i_mem_read(mem_read_mem),
        .o_mem_read(mem_read_wb),
        .i_ex_data_out(ex_data_out_mem),
        .o_ex_data_out(ex_data_out_wb),
        .i_reg_write_en(reg_write_en_mem),
        .o_reg_write_en(reg_write_en_wb),
        .i_rd_addr(rd_addr_mem),
        .o_rd_addr(rd_addr_wb),
        .i_reg_out_1(reg_out_1_mem),
        .o_reg_out_1(reg_out_1_wb),
        .i_reg_out_2(reg_out_2_mem),
        .o_reg_out_2(reg_out_2_wb),
        .i_rs1_addr(rs1_addr_mem),
        .o_rs1_addr(rs1_addr_wb),
        .i_rs2_addr(rs2_addr_mem),
        .o_rs2_addr(rs2_addr_wb),
        .i_rs1_used(rs1_used_mem),
        .o_rs1_used(rs1_used_wb),
        .i_rs2_used(rs2_used_mem),
        .o_rs2_used(rs2_used_wb),
        .i_halt(halt_mem),
        .o_halt(halt_wb),
        .i_valid(valid_mem),
        .o_valid(valid_wb),
        .i_instruction(instruction_mem),
        .o_instruction(instruction_wb),
        .i_dmem_addr(dcache_addr_int),
        .i_dmem_mask(dcache_mask_int),
        .i_dmem_ren(dcache_ren_int),
        .i_dmem_wen(dcache_wen_int),
        .i_dmem_wdata(dcache_wdata_int),
        .o_dmem_addr(dmem_addr_wb),
        .o_dmem_ren(o_retire_dmem_ren),
        .o_dmem_wen(o_retire_dmem_wen),
        .o_dmem_mask(dmem_mask_wb),
        .o_dmem_wdata(dmem_wdata_wb),
        .i_is_word(is_word_mem),
        .o_is_word(is_word_wb),
        .i_is_h_or_b(is_h_or_b_mem),
        .o_is_h_or_b(is_h_or_b_wb),
        .i_is_unsigned_ld(is_unsigned_ld_mem),
        .o_is_unsigned_ld(is_unsigned_ld_wb),
        .i_trap(trap_mem | mem_trap),
        .o_trap(trap_wb)
    );

    writeback Writeback(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .mem_read(mem_read_wb),
        .ex_data_out(ex_data_out_wb),
        .i_dmem_rdata(dcache_rdata),
        .is_word(is_word_wb),
        .is_h_or_b(is_h_or_b_wb),
        .is_unsigned_ld(is_unsigned_ld_wb),
        .reg_write_data(reg_write_data_wb),
        .mem_data_out(mem_data_out_wb)
    );

    assign o_retire_rs1_raddr = rs1_used_wb ? rs1_addr_wb : 5'd0;
    assign o_retire_rs2_raddr = rs2_used_wb ? rs2_addr_wb : 5'd0;
    assign o_retire_rd_waddr =  reg_write_en_wb ? rd_addr_wb : 5'd0;
    assign o_retire_rs1_rdata = rs1_used_wb ? reg_out_1_wb : 32'd0;
    assign o_retire_rs2_rdata = rs2_used_wb ? reg_out_2_wb : 32'd0;
    assign o_retire_rd_wdata =  reg_write_en_wb ? reg_write_data_wb : 32'd0;

    assign o_retire_inst = instruction_wb;
    assign o_retire_pc = pc_wb;

    assign o_retire_valid = (!dcache_busy && prev_dcache_busy) ? valid_cache : (dcache_busy && !prev_dcache_busy) ? 1'b0 : valid_wb;
    assign o_retire_next_pc = new_pc_wb;
    assign o_retire_trap = trap_wb;
    assign o_retire_halt = halt_wb;

    assign o_retire_dmem_rdata = dcache_rdata;
    assign o_retire_dmem_mask = dmem_mask_wb;
    assign o_retire_dmem_wdata = dmem_wdata_wb;
    assign o_retire_dmem_addr = dmem_addr_wb;
endmodule

`default_nettype wire