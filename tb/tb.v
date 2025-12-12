`timescale 1ns/1ps
module hart_tb ();
    // Synchronous active-high reset.
    reg         clk, rst;
    
    // Hart memory interface (caches talk to external memory through these)
    wire [31:0] mem_addr;
    wire        mem_ren, mem_wen;
    wire [31:0] mem_wdata;
    reg  [31:0] mem_rdata;
    reg         mem_valid;
    reg         mem_ready;
    
    // Arbiter signals for caches
    wire        imem_ren;
    reg         imem_ready, imem_valid;
    reg         dmem_ready, dmem_valid;
    
    // Cache statistics
    integer icache_hits, icache_misses;
    integer dcache_hits, dcache_misses;
    integer total_mem_reads, total_mem_writes;
    reg [31:0] prev_imem_addr, prev_dmem_addr;
    reg prev_imem_req, prev_dmem_req;
    
    // Hart to testbench 
    wire [31:0] hart_imem_raddr, hart_dmem_addr;
    wire        hart_dmem_ren, hart_dmem_wen;
    wire [31:0] hart_dmem_wdata;
    wire [ 3:0] hart_dmem_mask;

    // Instruction retire interface.
    wire        valid, trap, halt;
    wire [31:0] inst;
    wire [ 4:0] rs1_raddr, rs2_raddr;
    wire [31:0] rs1_rdata, rs2_rdata;
    wire [ 4:0] rd_waddr;
    wire [31:0] rd_wdata;
    wire [31:0] pc, next_pc;
    
    // Additional retire interface signals for memory debugging
    wire [31:0] retire_dmem_addr;
    wire        retire_dmem_ren;
    wire        retire_dmem_wen;
    wire [ 3:0] retire_dmem_mask;
    wire [31:0] retire_dmem_wdata;
    wire [31:0] retire_dmem_rdata;

    // Memory arrays
    reg [31:0] program[0:1023];
    reg [31:0] data_mem[0:16383];  // Increased to cover 0x0000-0xFFFC (64KB)
    integer i;  // Loop variable
    
    // Memory controller state machine with configurable latency
    parameter IDLE = 2'b00, READ = 2'b01, WRITE = 2'b10;
    reg [1:0] mem_state;
    reg [31:0] pending_addr;
    reg [2:0] mem_latency_counter;  // Variable latency support
    parameter MEM_LATENCY = 1;  // Configurable: 1-7 cycles
    
    hart #(
        .RESET_ADDR (32'h0)
    ) dut (
        .i_clk        (clk),
        .i_rst        (rst),
        .o_imem_raddr (hart_imem_raddr),
        .i_imem_rdata (32'h0),  // Obsolete, caches now inside
        .o_dmem_addr  (hart_dmem_addr),
        .o_dmem_ren   (hart_dmem_ren),
        .o_dmem_wen   (hart_dmem_wen),
        .o_dmem_wdata (hart_dmem_wdata),
        .o_dmem_mask  (hart_dmem_mask),
        .i_dmem_rdata (32'h0),  // Obsolete, caches now inside
        // Cache memory interface
        .o_mem_ren    (mem_ren),
        .o_mem_wen    (mem_wen),
        .o_mem_addr   (mem_addr),
        .o_mem_wdata  (mem_wdata),
        .i_mem_rdata  (mem_rdata),
        .i_mem_valid  (mem_valid),
        .i_mem_ready  (mem_ready),
        // Arbiter ports for separate cache control
        .o_imem_ren   (imem_ren),
        .i_imem_ready (imem_ready),
        .i_imem_valid (imem_valid),
        .i_dmem_ready (dmem_ready),
        .i_dmem_valid (dmem_valid),
        // Retire interface
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
        .o_retire_dmem_addr (retire_dmem_addr),
        .o_retire_dmem_ren  (retire_dmem_ren),
        .o_retire_dmem_wen  (retire_dmem_wen),
        .o_retire_dmem_mask (retire_dmem_mask),
        .o_retire_dmem_wdata(retire_dmem_wdata),
        .o_retire_dmem_rdata(retire_dmem_rdata)
    );

    // Testbench memory arbiter - mirrors hart's internal arbiter
    // Give icache priority when it needs memory (indicated by imem_ren)
    wire grant_icache = imem_ren;  // imem_ren correctly indicates icache memory request
    
    always @(*) begin
        if (grant_icache) begin
            // Icache has priority and is requesting memory
            imem_ready = mem_ready;
            imem_valid = mem_valid;
            dmem_ready = 1'b0;
            dmem_valid = 1'b0;
        end else begin
            // Icache not requesting, dcache gets access
            imem_ready = 1'b0;
            imem_valid = 1'b0;
            dmem_ready = mem_ready;
            dmem_valid = mem_valid;
        end
    end

    // Memory controller FSM - simulates configurable memory latency
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_state <= IDLE;
            mem_valid <= 1'b0;
            mem_ready <= 1'b1;  // Memory is always ready
            mem_rdata <= 32'h0;
            pending_addr <= 32'h0;
            mem_latency_counter <= 0;
        end else begin
            case (mem_state)
                IDLE: begin
                    mem_valid <= 1'b0;
                    mem_ready <= 1'b1;  // Always ready to accept requests
                    if (mem_ren) begin
                        mem_state <= READ;
                        pending_addr <= mem_addr;
                        mem_latency_counter <= MEM_LATENCY;
                    end else if (mem_wen) begin
                        mem_state <= WRITE;
                        pending_addr <= mem_addr;
                        mem_latency_counter <= MEM_LATENCY;
                        // Write to memory (word-aligned)
                        data_mem[mem_addr[31:2]] <= mem_wdata;
                    end
                end
                
                READ: begin
                    mem_ready <= 1'b1;  // Keep ready high
                    // Simulate memory latency
                    if (mem_latency_counter > 1) begin
                        mem_latency_counter <= mem_latency_counter - 1;
                    end else begin
                        // Return data for one cycle then go back to IDLE
                        // Check if address is in data memory range (0x1000+) or program range
                        if (pending_addr[31:12] != 20'h0) begin
                            // Data memory (addresses >= 0x1000)
                            mem_rdata <= data_mem[pending_addr[31:2]];
                        end else begin
                            // Program memory (addresses < 0x1000)
                            mem_rdata <= program[pending_addr[31:2]];
                        end
                        mem_valid <= 1'b1;
                        mem_state <= IDLE;
                    end
                end
                
                WRITE: begin
                    mem_ready <= 1'b1;  // Keep ready high
                    // Simulate write latency
                    if (mem_latency_counter > 1) begin
                        mem_latency_counter <= mem_latency_counter - 1;
                    end else begin
                        // Write completes, return valid for one cycle
                        mem_valid <= 1'b1;
                        mem_state <= IDLE;
                    end
                end
                
                default: begin
                    mem_state <= IDLE;
                    mem_valid <= 1'b0;
                    mem_ready <= 1'b1;
                end
            endcase
        end
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Load program memory
        $readmemh("tb/program.mem", program);
        
        // Initialize data memory with test patterns
        for (i = 0; i < 16384; i = i + 1) begin
            data_mem[i] = 32'h0;
        end
        
        // Add some test data for load instructions
        data_mem[0] = 32'hDEADBEEF;
        data_mem[1] = 32'h12345678;
        data_mem[2] = 32'hCAFEBABE;
        data_mem[3] = 32'hFEEDFACE;
        
        // Initialize cache statistics
        icache_hits = 0;
        icache_misses = 0;
        dcache_hits = 0;
        dcache_misses = 0;
        total_mem_reads = 0;
        total_mem_writes = 0;
        prev_imem_req = 0;
        prev_dmem_req = 0;
        
        // Reset
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        
        // Run until halt or timeout
        repeat (10000) @(posedge clk) begin
            if (halt) begin
                $display("\n=======================================================");
                $display("  SIMULATION COMPLETE - HALT");
                $display("=======================================================");
                print_statistics();
                $finish;
            end
            
            if (trap) begin
                $display("\n=======================================================");
                $display("  SIMULATION COMPLETE - TRAP");
                $display("=======================================================");
                $display("Trap at cycle %0d", $time/10);
                $display("PC: 0x%08x", pc);
                $display("Instruction: 0x%08x", inst);
                print_statistics();
                $finish;
            end
        end
        
        $display("\n=======================================================");
        $display("  SIMULATION TIMEOUT");
        $display("=======================================================");
        print_statistics();
        $finish;
    end
    
    // Task to print cache statistics
    task print_statistics;
        real icache_hit_rate, dcache_hit_rate;
        integer total_icache_accesses, total_dcache_accesses;
        begin
            total_icache_accesses = icache_hits + icache_misses;
            total_dcache_accesses = dcache_hits + dcache_misses;
            
            if (total_icache_accesses > 0)
                icache_hit_rate = (100.0 * icache_hits) / total_icache_accesses;
            else
                icache_hit_rate = 0.0;
                
            if (total_dcache_accesses > 0)
                dcache_hit_rate = (100.0 * dcache_hits) / total_dcache_accesses;
            else
                dcache_hit_rate = 0.0;
            
            $display("\nInstruction Cache Statistics:");
            $display("  Total Accesses: %0d", total_icache_accesses);
            $display("  Hits:           %0d", icache_hits);
            $display("  Misses:         %0d", icache_misses);
            $display("  Hit Rate:       %0.2f%%", icache_hit_rate);
            
            $display("\nData Cache Statistics:");
            $display("  Total Accesses: %0d", total_dcache_accesses);
            $display("  Hits:           %0d", dcache_hits);
            $display("  Misses:         %0d", dcache_misses);
            $display("  Hit Rate:       %0.2f%%", dcache_hit_rate);
            
            $display("\nMemory Interface Statistics:");
            $display("  Total Reads:    %0d", total_mem_reads);
            $display("  Total Writes:   %0d", total_mem_writes);
            
            $display("\nOverall Performance:");
            $display("  Total Cycles:   %0d", cycle_count);
            if (valid)
                $display("  Final PC:       0x%08x", pc);
            end
    endtask

    // Monitor instruction retirement
    integer cycle_count;
    initial begin
        cycle_count = 0;
        forever begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            if (!rst && valid) begin
                $display("[%0d] PC=0x%08x INST=0x%08x", cycle_count, pc, inst);
                
                if (rd_waddr != 0) begin
                    $display("     x%0d <- 0x%08x", rd_waddr, rd_wdata);
                end
                
                if (retire_dmem_ren) begin
                    $display("     MEM[0x%08x] -> 0x%08x (mask=%b)", 
                        retire_dmem_addr, retire_dmem_rdata, retire_dmem_mask);
                end
                
                if (retire_dmem_wen) begin
                    $display("     MEM[0x%08x] <- 0x%08x (mask=%b)", 
                        retire_dmem_addr, retire_dmem_wdata, retire_dmem_mask);
                end
            end
        end
    end
    
    // Cache performance monitoring - track hits and misses
    always @(posedge clk) begin
        if (!rst) begin
            // Track instruction cache activity
            // Detect icache miss by checking busy signal transitions
            if (dut.icache_busy && !prev_imem_req) begin
                icache_misses = icache_misses + 1;
                $display("     [ICACHE MISS] Address: 0x%08x", hart_imem_raddr);
            end else if (!dut.icache_busy && !prev_imem_req) begin
                icache_hits = icache_hits + 1;
            end
            prev_imem_req = dut.icache_busy;
            
            // Track data cache activity
            if (hart_dmem_ren || hart_dmem_wen) begin
                if (dut.dcache_busy && !prev_dmem_req) begin
                    dcache_misses = dcache_misses + 1;
                    $display("     [DCACHE MISS] Address: 0x%08x %s", 
                        hart_dmem_addr, hart_dmem_wen ? "(WRITE)" : "(READ)");
                end else if (!dut.dcache_busy) begin
                    dcache_hits = dcache_hits + 1;
                end
                prev_dmem_req = dut.dcache_busy;
            end else begin
                prev_dmem_req = 0;
            end
            
            // Track memory interface activity
            if (mem_ren && mem_ready) begin
                total_mem_reads = total_mem_reads + 1;
            end
            if (mem_wen && mem_ready) begin
                total_mem_writes = total_mem_writes + 1;
            end
        end
    end

endmodule
