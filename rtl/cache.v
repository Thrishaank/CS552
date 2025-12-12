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

    wire hit;
    reg eval_hit;

    reg [1:0] state;
    reg [1:0] next_state;
    reg update_data, update_tag, update_valid, update_lru;
    reg cache_write, first_mem_read, mem_write;
    reg cache_written, mem_written;
    reg done;
    wire in_0, in_1;
    reg was_write;
    reg idled_first_cycle;
    reg idled_first, should_idle;

    integer i;
    integer j;

    reg next_word;
    reg [1:0] read_word_cnt, read_word_cnt_prev;

    localparam IDLE = 2'b00;
    localparam EVAL = 2'b01;
    localparam MEM_READ = 2'b10;
    localparam MEM_WRITE = 2'b11;
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            read_word_cnt <= 2'b00;
        end else if (next_word) begin
            read_word_cnt <= read_word_cnt + 1'b1;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin 
            read_word_cnt_prev <= 2'b00;
        end else begin
            read_word_cnt_prev <= read_word_cnt;
        end
    end

    always @(posedge i_clk) begin
        if (done) begin
            cache_written <= 1'b0;
        end else if (cache_write) begin
            cache_written <= 1'b1;
        end
    end

    always @(posedge i_clk) begin
        if (done) begin
            mem_written <= 1'b0;
        end else if (mem_write) begin
            mem_written <= 1'b1;
        end
    end

    always @(posedge i_clk) begin
        if (i_req_wen) begin
             was_write <= 1'b1;
        end else if (i_req_ren) begin
             was_write <= 1'b0;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            idled_first_cycle = 1'b1;
        end else if (idled_first) begin
            idled_first_cycle = 1'b1;
        end else if (should_idle) begin
            idled_first_cycle = 1'b0;
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
        mem_write = 1'b0;
        first_mem_read = 1'b0;
        idled_first = 1'b0;
        should_idle = 1'b0;

        if (state == IDLE) begin
            done = 1'b1;
            // if (~idled_first_cycle) begin
            //     idled_first = 1'b1;
            // end else 
            if (i_req_ren | i_req_wen) begin
                next_state = EVAL;
                eval_hit = 1'b1;
            end
        end else if (state == EVAL) begin
            eval_hit = 1'b1;
            if (~hit) begin
                if (i_mem_ready) begin
                    next_state = MEM_READ;
                    first_mem_read = 1'b1;
                end
            end else if (was_write) begin
                update_lru = 1'b1;
                done = 1'b1;
            end else begin
                done = 1'b1;
                // next_state = IDLE;
                should_idle = 1'b1;
            end
        end else if (state == MEM_READ) begin
            if (i_mem_valid & (read_word_cnt == D - 1)) begin
                if (was_write) begin
                    next_state = MEM_WRITE;
                end else begin
                    next_state = IDLE;
                    update_lru = 1'b1;
                    should_idle = 1'b1;
                end
                update_data = 1'b1;
                next_word = 1'b1;
            end else if (i_mem_valid && (read_word_cnt == D - 2)) begin
                update_data = 1'b1;
                update_tag = 1'b1;
                update_valid = 1'b1;
                next_word = 1'b1;
            end else if (i_mem_valid & (read_word_cnt != D - 1)) begin
                next_word = 1'b1;
                update_data = 1'b1;
            end

        end else if (state == MEM_WRITE) begin
            update_lru = 1'b1;
            next_state = IDLE;
            // if (~cache_written) begin
            //     cache_write = 1'b1;
            // end else if (cache_written & ~mem_written) begin
            //     mem_write = 1'b1;
            // end else if (cache_written & mem_written) begin
            //     next_state = IDLE;
            //     update_lru = 1'b1;
            //     should_idle = 1'b1;
            // end
        end
    end

    assign in_0 = (i_req_addr[31:S+O] == tags0[i_req_addr[O+S-1:O]] && valid[i_req_addr[O+S-1:O]][0]);
    assign in_1 = (i_req_addr[31:S+O] == tags1[i_req_addr[O+S-1:O]] && valid[i_req_addr[O+S-1:O]][1]);

    assign hit = in_0 || in_1;

    // Busy is high on miss, tag in corresponding cache line does not match request address
    assign o_busy = (~hit | ~done);

    assign o_res_rdata = i_req_addr[31:S+O] == tags0[i_req_addr[O+S-1:O]] ? datas0[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] :
                         i_req_addr[31:S+O] == tags1[i_req_addr[O+S-1:O]] ? datas1[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] :
                         32'hxxxxxxx;

    // Memory read/write logic
    assign o_mem_addr = {i_req_addr[31:O], read_word_cnt, 2'b00};
    assign o_mem_ren  = (read_word_cnt != read_word_cnt_prev && state == MEM_READ) || first_mem_read;
    assign o_mem_wen  = hit & was_write;
    assign o_mem_wdata = (in_0) ? (datas0[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] & ~{ {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) | (i_req_wdata & { {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) 
                                : (datas1[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] & ~{ {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) | (i_req_wdata & { {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} })           ;

    // Cache valid logic
    always @(posedge i_clk) begin
        if (i_rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                valid[i] <= 2'b00;
            end
        end else if (update_valid) begin
            if (lru[i_req_addr[O+S-1:O]] == 1'b0) begin
                valid[i_req_addr[O+S-1:O]][0] <= 1'b1;
            end else begin
                valid[i_req_addr[O+S-1:O]][1] <= 1'b1;
            end
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            for (j = 0; j < DEPTH; j = j + 1) begin
                lru[j] <= 1'b0;
            end
        end else if (update_lru) begin
            if (in_0) begin
                lru[i_req_addr[O+S-1:O]] <= 1'b1;
            end else if (in_1) begin
                lru[i_req_addr[O+S-1:O]] <= 1'b0;
            end
        end
    end

    always @(posedge i_clk) begin
        if (update_data & (!was_write || read_word_cnt != i_req_addr[O-1:2])) begin
            if (lru[i_req_addr[O+S-1:O]] == 1'b0) begin
                datas0[i_req_addr[O+S-1:O]][read_word_cnt] <= i_mem_rdata;
            end else begin
                datas1[i_req_addr[O+S-1:O]][read_word_cnt] <= i_mem_rdata;
            end
        end else if (update_data & was_write & read_word_cnt == i_req_addr[O-1:2]) begin
            if (lru[i_req_addr[O+S-1:O]] == 1'b0) begin
                datas0[i_req_addr[O+S-1:O]][read_word_cnt] <= (i_mem_rdata & ~{ {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) | (i_req_wdata & { {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} });
            end else begin
                datas1[i_req_addr[O+S-1:O]][read_word_cnt] <= (i_mem_rdata & ~{ {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) | (i_req_wdata & { {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} });
            end
        end else if (hit & i_req_wen) begin
            if (in_0) begin
                datas0[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] <= (datas0[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] & ~{ {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) | (i_req_wdata & { {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} });
            end else if (in_1) begin
                datas1[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] <= (datas1[i_req_addr[O+S-1:O]][i_req_addr[O-1:2]] & ~{ {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} }) | (i_req_wdata & { {8{i_req_mask[3]}}, {8{i_req_mask[2]}}, {8{i_req_mask[1]}}, {8{i_req_mask[0]}} });
            end
        end
    end

    always @(posedge i_clk) begin
        if (update_tag) begin
            if (lru[i_req_addr[O+S-1:O]] == 1'b0) begin
                tags0[i_req_addr[O+S-1:O]] <= i_req_addr[31:S+O];
            end else begin
                tags1[i_req_addr[O+S-1:O]] <= i_req_addr[31:S+O];
            end
        end
    end


endmodule

`default_nettype wire
`default_nettype wire