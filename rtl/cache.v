
`default_nettype none

module cache (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // External memory interface. See hart interface for details. This
    // interface is nearly identical to the phase 5 memory interface, with the
    // exception that the byte mask (`o_mem_mask`) has been removed. This is
    // no longer needed as the cache will only access the memory at word
    // granularity, and implement masking internally.
    input  wire        i_mem_ready,
    output wire [31:0] o_mem_addr,
    output wire        o_mem_ren,
    output wire        o_mem_wen,
    output wire [31:0] o_mem_wdata,
    input  wire [31:0] i_mem_rdata,
    input  wire        i_mem_valid,
    // Interface to CPU hart. This is nearly identical to the phase 5 hart memory
    // interface, but includes a stall signal (`o_busy`), and the input/output
    // polarities are swapped for obvious reasons.
    //
    // The CPU should use this as a stall signal for both instruction fetch
    // (IF) and memory (MEM) stages, from the instruction or data cache
    // respectively. If a memory request is made (`i_req_ren` for instruction
    // cache, or either `i_req_ren` or `i_req_wen` for data cache), this
    // should be asserted *combinationally* if the request results in a cache
    // miss.
    //
    // In case of a cache miss, the CPU must stall the respective pipeline
    // stage and deassert ren/wen on subsequent cycles, until the cache
    // deasserts `o_busy` to indicate it has serviced the cache miss. However,
    // the CPU must keep the other request lines constant. For example, the
    // CPU should not change the request address while stalling.
    output wire        o_busy,
    // 32-bit read/write address to access from the cache. This should be
    // 32-bit aligned (i.e. the two LSBs should be zero). See `i_req_mask` for
    // how to perform half-word and byte accesses to unaligned addresses.
    input  wire [31:0] i_req_addr,
    // When asserted, the cache should perform a read at the aligned address
    // specified by `i_req_addr` and return the 32-bit word at that address,
    // either immediately (i.e. combinationally) on a cache hit, or
    // synchronously on a cache miss. It is illegal to assert this and
    // `i_dmem_wen` on the same cycle.
    input  wire        i_req_ren,
    // When asserted, the cache should perform a write at the aligned address
    // specified by `i_req_addr` with the 32-bit word provided in
    // `o_req_wdata` (specified by the mask). This is necessarily synchronous,
    // but may either happen on the next clock edge (on a cache hit) or after
    // multiple cycles of latency (cache miss). As the cache is write-through
    // and write-allocate, writes must be applied to both the cache and
    // underlying memory.
    // It is illegal to assert this and `i_dmem_ren` on the same cycle.
    input  wire        i_req_wen,
    // The memory interface expects word (32 bit) aligned addresses. However,
    // WISC-25 supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    input  wire [ 3:0] i_req_mask,
    // The 32-bit word to write to memory, if the request is a write
    // (i_req_wen is asserted). Only the bytes corresponding to set bits in
    // the mask should be written into the cache (and to backing memory).
    input  wire [31:0] i_req_wdata,
    // THe 32-bit data word read from memory on a read request.
    output wire [31:0] o_res_rdata
);
    // These parameters are equivalent to those provided in the project
    // 6 specification. Feel free to use them, but hardcoding these numbers
    // rather than using the localparams is also permitted, as long as the
    // same values are used (and consistent with the project specification).
    //
    // 32 sets * 2 ways per set * 16 bytes per way = 1K cache
    localparam O = 4;            // 4 bit offset => 16 byte cache line
    localparam S = 5;            // 5 bit set index => 32 sets
    localparam DEPTH = 2 ** S;   // 32 sets
    localparam W = 2;            // 2 way set associative, NMRU
    localparam T = 32 - O - S;   // 23 bit tag
    localparam D = 2 ** O / 4;   // 16 bytes per line / 4 bytes per word = 4 words per line

    // The following memory arrays model the cache structure. As this is
    // an internal implementation detail, you are *free* to modify these
    // arrays as you please.

    // Backing memory, modeled as two separate ways.
    reg [   31:0] datas0 [DEPTH - 1:0][D - 1:0];
    reg [   31:0] datas1 [DEPTH - 1:0][D - 1:0];
    reg [T - 1:0] tags0  [DEPTH - 1:0];
    reg [T - 1:0] tags1  [DEPTH - 1:0];
    reg [1:0] valid [DEPTH - 1:0];
    reg       lru   [DEPTH - 1:0];

    integer i, j;  // Loop variables for initialization

    wire hit;
    reg eval_hit;

    reg [1:0] state;
    reg [1:0] next_state;
    reg update_data, update_tag, update_valid, update_lru;
    reg cache_write;
    reg done;
    reg hit_way;  // Track which way hit: 0 for way0, 1 for way1
    reg data_way; // Track which way to read data from
    wire in_0, in_1;

    integer byte_idx;

    reg [31:0] req_addr_latched;  // Latch request address
    reg [31:0] req_wdata_latched; // Latch write data
    reg [3:0]  req_mask_latched;  // Latch write mask
    reg req_wen_latched;          // Latch write enable
    wire [31:0] addr_for_cache;   // Select current or latched address
    reg next_word;
    reg [1:0] read_word_cnt;

    localparam IDLE = 2'b00;
    localparam EVAL = 2'b01;
    localparam MEM_READ = 2'b10;
    localparam MEM_WRITE = 2'b11;
    
    // Use current address in IDLE for immediate hit detection, latched otherwise
    assign addr_for_cache = (state == IDLE) ? i_req_addr : req_addr_latched;
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
            hit_way <= 1'b0;
            data_way <= 1'b0;
        end else begin
            state <= next_state;
            // Capture which way hit WHEN ENTERING EVAL state from IDLE
            // Use i_req_addr since req_addr_latched isn't set until this same clock edge
            if ((state == IDLE) && (next_state == EVAL)) begin
                if (hit) begin
                    // Hit: determine which way matched
                    if (i_req_addr[31:S+O] == tags0[i_req_addr[O+S-1:O]] && valid[i_req_addr[O+S-1:O]][0]) begin
                        data_way <= 1'b0;
                        hit_way <= 1'b0;
                    end else begin
                        data_way <= 1'b1;
                        hit_way <= 1'b1;
                    end
                end else begin
                    // Miss: use LRU to determine which way to allocate
                    hit_way <= lru[i_req_addr[O+S-1:O]];
                    data_way <= lru[i_req_addr[O+S-1:O]];
                end
            end
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            read_word_cnt <= 2'b00;
        end else if (state == EVAL && next_state == MEM_READ) begin
            read_word_cnt <= 2'b00;  // Reset counter when starting line fill
        end else if (next_word) begin
            read_word_cnt <= read_word_cnt + 1'b1;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            req_addr_latched <= 32'h0;
            req_wdata_latched <= 32'h0;
            req_mask_latched <= 4'h0;
            req_wen_latched <= 1'b0;
        end else if (state == IDLE && next_state == EVAL) begin
            req_addr_latched <= i_req_addr;  // Latch address at start of transaction
            req_wdata_latched <= i_req_wdata; // Latch write data
            req_mask_latched <= i_req_mask;   // Latch write mask
            req_wen_latched <= i_req_wen;     // Latch write enable
        end
    end

    always @(*) begin
        next_state = state;
        eval_hit = 1'b0;
        done = 1'b0;
        update_tag = 1'b0;
        update_valid = 1'b0;
        update_data = 1'b0;
        next_word = 1'b0;
        update_lru = 1'b0;
        cache_write = 1'b0;

        if (state == IDLE) begin
            if (i_req_ren | i_req_wen) begin
                done = 1'b0;  // New request, not done yet
                next_state = EVAL;
                eval_hit = 1'b1;
            end else begin
                done = 1'b1;  // No request, idle and done
            end
        end else if (state == EVAL) begin
            eval_hit = 1'b1;
            if (~hit) begin
                next_state = MEM_READ;
            end else begin
                if (req_wen_latched) begin
                    // Write hit: update cache and write through to memory, but don't stall CPU
                    // Complete in one cycle, no busy signal
                    cache_write = 1'b1;
                    update_lru = 1'b1;
                    next_state = IDLE;
                    done = 1'b1;  // Done immediately on write hit
                end else begin
                    // Read hit: done
                    update_lru = 1'b1;  // Update LRU on read hit
                    done = 1'b1;
                    next_state = IDLE;
                end
            end
        end else if (state == MEM_READ) begin
            if (i_mem_valid & (read_word_cnt == D - 1)) begin
                next_state = (req_wen_latched) ? MEM_WRITE : IDLE;
                done = (req_wen_latched) ? 1'b0 : 1'b1;
                update_data = 1'b1;
                update_tag = 1'b1;
                update_valid = 1'b1;
                update_lru = 1'b1;  // Update LRU after line fill completes
                next_word = 1'b1;
            end else if (i_mem_valid & (read_word_cnt != D - 1)) begin
                next_word = 1'b1;
                update_data = 1'b1;
            end
        end else if (state == MEM_WRITE) begin
            cache_write = 1'b1;
            update_lru = 1'b1;  // Update LRU after write completes
            next_state = IDLE;
            done = 1'b1;
        end
    end

    // Hit detection for immediate response (uses addr_for_cache)
    assign in_0 = (addr_for_cache[31:S+O] == tags0[addr_for_cache[O+S-1:O]] && valid[addr_for_cache[O+S-1:O]][0]);
    assign in_1 = (addr_for_cache[31:S+O] == tags1[addr_for_cache[O+S-1:O]] && valid[addr_for_cache[O+S-1:O]][1]);

    // Hit detection for data path (uses req_addr_latched)
    wire in_0_latched = (req_addr_latched[31:S+O] == tags0[req_addr_latched[O+S-1:O]] && valid[req_addr_latched[O+S-1:O]][0]);
    wire in_1_latched = (req_addr_latched[31:S+O] == tags1[req_addr_latched[O+S-1:O]] && valid[req_addr_latched[O+S-1:O]][1]);

    assign hit = in_0 || in_1;

    // Busy when: not in IDLE and not done, OR in IDLE with new miss request
    assign o_busy = (state != IDLE & ~done) | ((state == IDLE) & (i_req_ren | i_req_wen) & ~hit);

    // Always use latched address for reading data from arrays
    wire [1:0] read_word_index = req_addr_latched[O-1:2];
    wire [O+S-1:O] read_set_index = req_addr_latched[O+S-1:O];
    
    // For reads: use data_way register (set when entering EVAL)
    assign o_res_rdata = (data_way == 1'b0) ? datas0[read_set_index][read_word_index] :
                                               datas1[read_set_index][read_word_index];

    // Memory read/write logic
    // On MEM_READ, stream the whole line starting at the line-aligned address.
    // On MEM_WRITE, write the specific word-aligned address of the request.
    wire [31:0] mem_addr_read  = {req_addr_latched[31:O], read_word_cnt, 2'b00};
    wire [31:0] mem_addr_write = {req_addr_latched[31:2], 2'b00};
    assign o_mem_addr = (state == MEM_READ) ? mem_addr_read : mem_addr_write;
    assign o_mem_ren  = (state == MEM_READ);
    assign o_mem_wen  = (state == MEM_WRITE) | (state == EVAL & hit & req_wen_latched);

    // Masked write-through data: merge existing cached word with requested bytes.
    // This ensures external memory observes the same byte updates as the cache.
    wire [31:0] byte_mask32 = { {8{req_mask_latched[3]}}, {8{req_mask_latched[2]}}, {8{req_mask_latched[1]}}, {8{req_mask_latched[0]}} };
    wire [31:0] cached_word_for_write = (hit_way == 1'b0)
        ? datas0[req_addr_latched[O+S-1:O]][req_addr_latched[O-1:2]]
        : datas1[req_addr_latched[O+S-1:O]][req_addr_latched[O-1:2]];
    wire [31:0] masked_wdata = (cached_word_for_write & ~byte_mask32) | (req_wdata_latched & byte_mask32);
    assign o_mem_wdata = masked_wdata;  // Write-through: send masked merge to memory

    // Cache valid logic
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                valid[i] <= 2'b00;
                tags0[i] <= {T{1'b1}};  // Initialize to all 1's to avoid false matches with 0 tags
                tags1[i] <= {T{1'b1}};
            end
        end else if (update_valid) begin
            if (hit_way == 1'b0) begin
                valid[req_addr_latched[O+S-1:O]][0] <= 1'b1;
            end else begin
                valid[req_addr_latched[O+S-1:O]][1] <= 1'b1;
            end
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            for (j = 0; j < DEPTH; j = j + 1) begin
                lru[j] <= 1'b0;
            end
        end else if (update_lru) begin
            // Use hit_way to determine which way was accessed
            // hit_way is set in EVAL for hits, or in MEM_READ for miss allocations
            if (hit_way == 1'b0) begin
                lru[req_addr_latched[O+S-1:O]] <= 1'b1;  // way 0 accessed, mark way 1 for next eviction
            end else begin
                lru[req_addr_latched[O+S-1:O]] <= 1'b0;  // way 1 accessed, mark way 0 for next eviction
            end
        end
    end

    always @(posedge i_clk) begin
        if (update_data) begin
            if (hit_way == 1'b0) begin
                datas0[req_addr_latched[O+S-1:O]][read_word_cnt] <= i_mem_rdata;
            end else begin
                datas1[req_addr_latched[O+S-1:O]][read_word_cnt] <= i_mem_rdata;
            end
        end else if (cache_write) begin
            if (hit_way == 1'b0) begin
                // Write to way 0
                datas0[req_addr_latched[O+S-1:O]][req_addr_latched[O-1:2]] <= (datas0[req_addr_latched[O+S-1:O]][req_addr_latched[O-1:2]] & ~{ {8{req_mask_latched[3]}}, {8{req_mask_latched[2]}}, {8{req_mask_latched[1]}}, {8{req_mask_latched[0]}} }) | (req_wdata_latched & { {8{req_mask_latched[3]}}, {8{req_mask_latched[2]}}, {8{req_mask_latched[1]}}, {8{req_mask_latched[0]}} });
            end else begin
                // Write to way 1
                datas1[req_addr_latched[O+S-1:O]][req_addr_latched[O-1:2]] <= (datas1[req_addr_latched[O+S-1:O]][req_addr_latched[O-1:2]] & ~{ {8{req_mask_latched[3]}}, {8{req_mask_latched[2]}}, {8{req_mask_latched[1]}}, {8{req_mask_latched[0]}} }) | (req_wdata_latched & { {8{req_mask_latched[3]}}, {8{req_mask_latched[2]}}, {8{req_mask_latched[1]}}, {8{req_mask_latched[0]}} });
            end
        end
    end

    always @(posedge i_clk) begin
        if (update_tag) begin
            if (hit_way == 1'b0) begin
                tags0[req_addr_latched[O+S-1:O]] <= req_addr_latched[31:S+O];
            end else begin
                tags1[req_addr_latched[O+S-1:O]] <= req_addr_latched[31:S+O];
            end
        end
    end


endmodule

`default_nettype wire