`timescale 1ns/1ps

module cache_tb();
    reg clk, rst;
    
    // Cache interface
    wire        busy;
    reg  [31:0] req_addr;
    reg         req_ren, req_wen;
    reg  [3:0]  req_mask;
    reg  [31:0] req_wdata;
    wire [31:0] res_rdata;
    
    // Memory interface
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire        mem_ren, mem_wen;
    wire [31:0] mem_wdata;
    reg  [31:0] mem_rdata;
    reg         mem_valid;
    
    // Memory model
    reg [31:0] memory [0:16383];
    reg [31:0] pending_addr;
    integer mem_latency;
    integer i;
    
    // Test tracking
    integer errors;
    integer test_num;
    
    cache dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_mem_ready(mem_ready),
        .o_mem_addr(mem_addr),
        .o_mem_ren(mem_ren),
        .o_mem_wen(mem_wen),
        .o_mem_wdata(mem_wdata),
        .i_mem_rdata(mem_rdata),
        .i_mem_valid(mem_valid),
        .o_busy(busy),
        .i_req_addr(req_addr),
        .i_req_ren(req_ren),
        .i_req_wen(req_wen),
        .i_req_mask(req_mask),
        .i_req_wdata(req_wdata),
        .o_res_rdata(res_rdata)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Memory model - simple 1-cycle latency
    always @(posedge clk) begin
        if (rst) begin
            mem_valid <= 0;
            mem_rdata <= 32'h0;
            pending_addr <= 32'h0;
            mem_latency <= 0;
        end else begin
            mem_valid <= 0;
            if (mem_ren && mem_ready) begin
                pending_addr <= mem_addr;
                mem_latency <= 1;
            end else if (mem_wen && mem_ready) begin
                memory[mem_addr[31:2]] <= mem_wdata;
                mem_latency <= 1;
            end
            
            if (mem_latency > 0) begin
                mem_latency <= mem_latency - 1;
                if (mem_latency == 1) begin
                    mem_valid <= 1;
                    if (!mem_wen)
                        mem_rdata <= memory[pending_addr[31:2]];
                end
            end
        end
    end
    
    // Task to perform cache read
    task cache_read;
        input [31:0] addr;
        input [3:0] mask;
        input [31:0] expected_data;
        input expected_hit;
        reg was_hit;
        integer cycle_count;
        begin
            req_addr = addr;
            req_ren = 1;
            req_wen = 0;
            req_mask = mask;
            
            // Count cycles until completion
            cycle_count = 0;
            @(posedge clk); // Allow FSM to transition
            cycle_count = cycle_count + 1;
            while (busy) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end
            req_ren = 0;  // Deassert after completion
            
            // Read hit takes ~2 cycles (IDLE->EVAL->done)
            // Read miss takes 5+ cycles (IDLE->EVAL->MEM_READ(4)->done)
            was_hit = (cycle_count <= 3);
            
            // Check result
            if (res_rdata !== expected_data) begin
                $display("Read %s:   addr=%08h data=%08h mask=%04b  <-- WRONG (expected: Read %s:   addr=%08h data=%08h mask=%04b)",
                    was_hit ? "HIT " : "MISS", addr, res_rdata, mask,
                    expected_hit ? "HIT " : "MISS", addr, expected_data, mask);
                errors = errors + 1;
            end else begin
                $display("Read %s:   addr=%08h data=%08h mask=%04b",
                    was_hit ? "HIT " : "MISS", addr, res_rdata, mask);
            end
        end
    endtask
    
    // Task to perform cache write
    task cache_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0] mask;
        input expected_hit;
        reg was_hit;
        integer cycle_count;
        begin
            req_addr = addr;
            req_ren = 0;
            req_wen = 1;
            req_wdata = data;
            req_mask = mask;
            
            // Count cycles until completion
            cycle_count = 0;
            @(posedge clk); // Allow FSM to transition
            cycle_count = cycle_count + 1;
            while (busy) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end
            req_wen = 0;  // Deassert after completion
            
            // Write hit takes ~3 cycles (IDLE->EVAL->MEM_WRITE->done)
            // Write miss takes 6+ cycles (IDLE->EVAL->MEM_READ(4)->MEM_WRITE->done)
            was_hit = (cycle_count <= 4);
            
            if (was_hit != expected_hit) begin
                $display("Write %s: addr=%08h data=%08h mask=%04b  <-- WRONG (expected: Write %s:  addr=%08h data=%08h mask=%04b)",
                    was_hit ? "HIT " : "MISS", addr, data, mask,
                    expected_hit ? "HIT " : "MISS", addr, data, mask);
                errors = errors + 1;
            end else begin
                $display("Write %s: addr=%08h data=%08h mask=%04b",
                    was_hit ? "HIT " : "MISS", addr, data, mask);
            end
        end
    endtask
    
    // Main test
    initial begin
        // Initialize
        errors = 0;
        test_num = 0;
        rst = 1;
        req_addr = 0;
        req_ren = 0;
        req_wen = 0;
        req_mask = 4'b1111;
        req_wdata = 0;
        mem_ready = 1;
        
        // Load program memory with test pattern
        $readmemh("tb/program.mem", memory);
        
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);
        
        $display("\n=== Test 1: Basic Read/Write to same cache line ===");
        cache_write(32'h00000200, 32'h00000000, 4'b1111, 0); // MISS - allocate line
        cache_write(32'h00000204, 32'h11111111, 4'b1111, 1); // HIT - same line, word 1
        cache_write(32'h00000208, 32'h22222222, 4'b1111, 1); // HIT - same line, word 2
        cache_write(32'h0000020c, 32'h33333333, 4'b1111, 1); // HIT - same line, word 3
        
        cache_read(32'h00000200, 4'b1111, 32'h00000000, 1);
        cache_read(32'h00000204, 4'b1111, 32'h11111111, 1);
        cache_read(32'h00000208, 4'b1111, 32'h22222222, 1);
        cache_read(32'h0000020c, 4'b1111, 32'h33333333, 1);
        
        $display("\n=== Test 2: Multiple writes to same address ===");
        cache_write(32'h00000200, 32'hdeadbeef, 4'b1111, 1); // HIT - overwrite
        cache_write(32'h00000200, 32'hbeefcafe, 4'b1111, 1); // HIT - overwrite again
        cache_read(32'h00000200, 4'b1111, 32'hbeefcafe, 1);  // Should read last write
        
        $display("\n=== Test 3: Partial (masked) writes ===");
        cache_write(32'h00000200, 32'hbeef0000, 4'b1100, 1); // HIT - write upper 2 bytes
        cache_read(32'h00000200, 4'b1111, 32'hbeefcafe, 1);  // Should have beef in upper, cafe in lower
        
        cache_write(32'h00000200, 32'h0000cafe, 4'b0011, 1); // HIT - write lower 2 bytes
        cache_read(32'h00000200, 4'b1111, 32'hbeefcafe, 1);  // Should still be beefcafe
        
        $display("\n=== Test 4: Read from different words ===");
        cache_write(32'h00000400, 32'h44444444, 4'b1111, 0); // MISS - new line
        cache_write(32'h00000404, 32'h55555555, 4'b1111, 1); // HIT
        cache_write(32'h00000408, 32'h66666666, 4'b1111, 1); // HIT
        cache_write(32'h0000040c, 32'h77777777, 4'b1111, 1); // HIT
        
        cache_read(32'h00000400, 4'b1111, 32'h44444444, 1);
        cache_read(32'h00000404, 4'b1111, 32'h55555555, 1);
        cache_read(32'h00000408, 4'b1111, 32'h66666666, 1);
        cache_read(32'h0000040c, 4'b1111, 32'h77777777, 1);
        
        $display("\n=== Test 5: Read from unaligned addresses (word 2 and 3) ===");
        memory[32'h0/4] = 32'hcf9c8b5d;
        memory[32'h4/4] = 32'h2b80bfff;
        memory[32'h8/4] = 32'hdeadbeef;
        cache_read(32'h00000000, 4'b1111, 32'hcf9c8b5d, 0); // MISS word 0
        cache_read(32'h00000000, 4'b1111, 32'hcf9c8b5d, 1); // HIT word 0
        cache_read(32'h00000000, 4'b0011, 32'hcf9c8b5d, 1); // HIT word 0 (cache returns full word, CPU does masking)
        cache_read(32'h0000000a, 4'b1111, 32'h2b80bfff, 1); // HIT word 2 (offset 0xa = word 2, byte 2)
        
        // Final summary
        repeat(5) @(posedge clk);
        $display("\n========================================");
        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("Total errors: %0d", errors);
        end
        $display("========================================\n");
        $finish;
    end
    
    // Timeout
    initial begin
        #100000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
endmodule
