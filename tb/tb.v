`timescale 1ns/1ps
module hart_tb ();
        integer instruction_count;
        integer ext_idx;
        integer found_null;
        reg [1023:0] program_file;
    // Synchronous active-high reset.
    reg         clk, rst;
    // Instruction memory interface.
    reg  [31:0] imem_rdata, dmem_rdata;
    wire [31:0] imem_raddr, dmem_addr;
    // Data memory interface.
    wire        dmem_ren, dmem_wen;
    wire [31:0] dmem_wdata;
    wire [ 3:0] dmem_mask;

    // Instruction retire interface.
    wire        valid, trap, halt;
    wire [31:0] inst;
    wire [ 4:0] rs1_raddr, rs2_raddr;
    wire [31:0] rs1_rdata, rs2_rdata;
    wire [ 4:0] rd_waddr;
    wire [31:0] rd_wdata;
    wire [31:0] pc, next_pc;

    // Dummy/testbench signals for unconnected ports
    wire i_imem_ready = 1'b1;
    wire o_imem_ren;
    wire i_imem_valid = 1'b1;
    wire i_dmem_ready = 1'b1;
    wire i_dmem_valid = 1'b1;
    wire [31:0] o_retire_dmem_addr;
    wire [3:0]  o_retire_dmem_mask;
    wire o_retire_dmem_ren;
    wire o_retire_dmem_wen;
    wire [31:0] o_retire_dmem_rdata;
    wire [31:0] o_retire_dmem_wdata;

    hart #(
        .RESET_ADDR (32'h0)
    ) dut (
        .i_clk        (clk),
        .i_rst        (rst),
        .o_imem_raddr (imem_raddr),
        .i_imem_rdata (imem_rdata),
        .i_imem_ready (i_imem_ready),
        .o_imem_ren   (o_imem_ren),
        .i_imem_valid (i_imem_valid),
        .o_dmem_addr  (dmem_addr),
        .o_dmem_ren   (dmem_ren),
        .o_dmem_wen   (dmem_wen),
        .o_dmem_wdata (dmem_wdata),
        .o_dmem_mask  (dmem_mask),
        .i_dmem_rdata (dmem_rdata),
        .i_dmem_ready (i_dmem_ready),
        .i_dmem_valid (i_dmem_valid),
        .o_retire_valid     (valid),
        .o_retire_inst      (inst),
        .o_retire_trap      (trap),
        .o_retire_halt      (halt),
        .o_retire_rs1_raddr (rs1_raddr),
        .o_retire_rs1_rdata (rs1_rdata),
        .o_retire_rs2_raddr (rs2_raddr),
        .o_retire_rs2_rdata (rs2_rdata),
        .o_retire_rd_waddr  (rd_waddr),
        .o_retire_rd_wdata  (rd_wdata),
        .o_retire_pc        (pc),
        .o_retire_next_pc   (next_pc),
        .o_retire_dmem_addr (o_retire_dmem_addr),
        .o_retire_dmem_mask (o_retire_dmem_mask),
        .o_retire_dmem_ren  (o_retire_dmem_ren),
        .o_retire_dmem_wen  (o_retire_dmem_wen),
        .o_retire_dmem_rdata(o_retire_dmem_rdata),
        .o_retire_dmem_wdata(o_retire_dmem_wdata)
    );

    // The tesbench uses separate instruction and data memory banks.
    reg [7:0] imem [0:1023];
    reg [7:0] dmem [0:1023];

    // Instruction memory read.
    always @(*) begin
        imem_rdata = {imem[imem_raddr + 3], imem[imem_raddr + 2], imem[imem_raddr + 1], imem[imem_raddr + 0]};
    end

    // Data memory read. Masks are ignored since it is always safe
    // to access the full bytes in this memory.
    always @(*) begin
        if (dmem_ren)
            dmem_rdata = {dmem[dmem_addr + 3], dmem[dmem_addr + 2], dmem[dmem_addr + 1], dmem[dmem_addr + 0]};
        else
            dmem_rdata = 32'h0;
    end

    // Synchronous data memory write. Masks must be respected.
    // The byte order is little-endian.
    always @(posedge clk) begin
        if (dmem_wen & dmem_mask[0])
            dmem[dmem_addr + 0] <= dmem_wdata[ 7: 0];
        if (dmem_wen & dmem_mask[1])
            dmem[dmem_addr + 1] <= dmem_wdata[15: 8];
        if (dmem_wen & dmem_mask[2])
            dmem[dmem_addr + 2] <= dmem_wdata[23:16];
        if (dmem_wen & dmem_mask[3])
            dmem[dmem_addr + 3] <= dmem_wdata[31:24];
    end

    integer cycles;
    initial begin

        clk = 0;

        // Dynamically select program file using +program=<filename> plusarg
        if (!$value$plusargs("program=%s", program_file)) begin
            program_file = "benchmarks/bubblesort_large.hex";
            $display("[TB] No +program specified, using default: %s", program_file);
        end else begin
            // If user passed a .mem file, convert to .hex extension (assume extension is always last 4 chars)
            if (program_file[0 +: 4] != 0) begin // avoid empty string
                ext_idx = 0;
                found_null = 0;
                // Find the end of the string (null-terminated)
                for (ext_idx = 0; ext_idx < 1020 && !found_null; ext_idx = ext_idx + 1) begin
                    if (program_file[ext_idx +: 8] == 0)
                        found_null = 1;
                end
                if (ext_idx >= 4 && program_file[(ext_idx-4)*8 +: 32] == ".mem") begin
                    program_file[(ext_idx-4)*8 +: 32] = ".hex";
                end
            end
            $display("[TB] Loading program from: %s", program_file);
        end
        $readmemh(program_file, imem);

        // Reset the dut.
        $display("Resetting hart.");
        @(negedge clk); rst = 1;
        @(negedge clk); rst = 0;

        $display("Cycle  PC        Inst     rs1            rs2            [rd, load, store]");
        cycles = 0;
        instruction_count = 0;
        while (!halt) begin
            @(posedge clk);
            cycles = cycles + 1;
            $display("[DEBUG] Cycle %0d: PC=%08h, inst=%08h, valid=%0d, halt=%0d", cycles, pc, inst, valid, halt);
            if (valid)
                instruction_count = instruction_count + 1;
            if (valid) begin
                // Base information for all instructions.
                if (imem_rdata[3:0] == 4'b0111 || imem_rdata[6:0] == 7'b111_0011)
                    $write("%05d [%08h] %08h r[xx]=xxxxxxxx r[xx]=xxxxxxxx", cycles, pc, inst);
                else if (imem_rdata[6:0] == 7'b001_0011 || imem_rdata[6:0] == 7'b000_0011 || 
                         imem_rdata[6:0] == 7'b110_1111 || imem_rdata[6:0] == 7'b110_0111)
                    $write("%05d [%08h] %08h r[%d]=%08h r[xx]=xxxxxxxx", cycles, pc, inst, rs1_raddr, rs1_rdata);
                else
                    $write("%05d [%08h] %08h r[%d]=%08h r[%d]=%08h", cycles, pc, inst, rs1_raddr, rs1_rdata, rs2_raddr, rs2_rdata);
                // Only display write information for instructions that write.
                if (rd_waddr != 5'd0)
                    $write(" w[%d]=%08h", rd_waddr, rd_wdata);
                // Only display memory information for load/store instructions.
                if (dmem_ren)
                    $write(" l[%08h,%04b]=%08h", dmem_addr, dmem_mask, dmem_rdata);
                if (dmem_wen)
                    $write(" s[%08h,%04b]=%08h", dmem_addr, dmem_mask, dmem_wdata);
                // Display trap information if a trap occurred.
                if (trap)
                    $write(" TRAP");
                $display();
            end
        end

        $display("Program halted after %d cycles.", cycles);
        $display("r[a0]=%08h (%d)", dut.rf.mem[10], dut.rf.mem[10]);
        $display("Cycles: %0d, Instructions: %0d", cycles, instruction_count);
        if (instruction_count > 0)
            $display("CPI: %0.2f", cycles * 1.0 / instruction_count);
        else
            $display("CPI: N/A");
        $finish;
    end

    always
        #5 clk = ~clk;
endmodule