module board_top (
    input  wire        CLOCK_50,   // 50 MHz system clock
    input  wire [9:0]  SW,         // Slide switches
    input  wire [3:0]  KEY,        // Push buttons (active low)
    output wire [9:0]  LEDR        // Red LEDs
);

    // ==========================
    // Clock and Reset
    // ==========================
    wire clk = CLOCK_50;
    wire rst = ~KEY[0];  // Active high reset from KEY[0] (push button is active low)

    // ==========================
    // Hart (RISC-V Core) Signals
    // ==========================
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [31:0] dmem_addr;
    wire        dmem_ren;
    wire        dmem_wen;
    wire [31:0] dmem_wdata;
    wire [ 3:0] dmem_mask;
    wire [31:0] dmem_rdata;
    
    // Retire interface signals
    wire        retire_valid;
    wire [31:0] retire_inst;
    wire        retire_trap;
    wire        retire_halt;
    wire [ 4:0] retire_rs1_raddr;
    wire [ 4:0] retire_rs2_raddr;
    wire [31:0] retire_rs1_rdata;
    wire [31:0] retire_rs2_rdata;
    wire [ 4:0] retire_rd_waddr;
    wire [31:0] retire_rd_wdata;
    wire [31:0] retire_pc;
    wire [31:0] retire_next_pc;

    // ==========================
    // Instruction Memory (ROM)
    // ==========================
    reg [31:0] imem [0:1023];  // 4KB instruction memory (1024 words)

    initial begin
        $readmemh("../tb/program.mem", imem);
    end

    // Word-aligned instruction fetch
    assign imem_rdata = imem[imem_addr[11:2]];

    // ==========================
    // Data Memory (RAM)
    // ==========================
    reg [31:0] dmem [0:1023];  // 4KB data memory (1024 words)

    // Data memory read (combinational)
    assign dmem_rdata = dmem_ren ? dmem[dmem_addr[11:2]] : 32'h0;

    // Data memory write (synchronous)
    always @(posedge clk) begin
        if (dmem_wen) begin
            // Write only the bytes specified by the mask
            if (dmem_mask[0]) dmem[dmem_addr[11:2]][7:0]   <= dmem_wdata[7:0];
            if (dmem_mask[1]) dmem[dmem_addr[11:2]][15:8]  <= dmem_wdata[15:8];
            if (dmem_mask[2]) dmem[dmem_addr[11:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_mask[3]) dmem[dmem_addr[11:2]][31:24] <= dmem_wdata[31:24];
        end
    end

    // ==========================
    // Hart Instantiation
    // ==========================
    hart #(
        .RESET_ADDR(32'h00000000)
    ) u_hart (
        .i_clk              (clk),
        .i_rst              (rst),
        
        // Instruction memory interface
        .o_imem_raddr       (imem_addr),
        .i_imem_rdata       (imem_rdata),
        
        // Data memory interface
        .o_dmem_addr        (dmem_addr),
        .o_dmem_ren         (dmem_ren),
        .o_dmem_wen         (dmem_wen),
        .o_dmem_wdata       (dmem_wdata),
        .o_dmem_mask        (dmem_mask),
        .i_dmem_rdata       (dmem_rdata),
        
        // Retire interface
        .o_retire_valid     (retire_valid),
        .o_retire_inst      (retire_inst),
        .o_retire_trap      (retire_trap),
        .o_retire_halt      (retire_halt),
        .o_retire_rs1_raddr (retire_rs1_raddr),
        .o_retire_rs2_raddr (retire_rs2_raddr),
        .o_retire_rs1_rdata (retire_rs1_rdata),
        .o_retire_rs2_rdata (retire_rs2_rdata),
        .o_retire_rd_waddr  (retire_rd_waddr),
        .o_retire_rd_wdata  (retire_rd_wdata),
        .o_retire_pc        (retire_pc),
        .o_retire_next_pc   (retire_next_pc)
    );

    // ==========================
    // LED Display Logic
    // ==========================
    // Display strategy controlled by SW[9:8]:
    // SW[9:8] = 00: Show result from register x11 (a1) - factorial result
    // SW[9:8] = 01: Show retire_halt and retire_trap status
    // SW[9:8] = 10: Show current PC[9:0]
    // SW[9:8] = 11: Show retired instruction's rd_waddr and whether it's valid
    
    reg [9:0] led_display;
    
    always @(*) begin
        case (SW[9:8])
            2'b00: begin
                // Show low 10 bits of register x11 (a1) when it's written
                // x11 = register 11, which will hold factorial result
                if (retire_valid && (retire_rd_waddr == 5'd11)) begin
                    led_display = retire_rd_wdata[9:0];
                end else begin
                    led_display = 10'h000;  // Default when not writing to x11
                end
            end
            
            2'b01: begin
                // Show halt/trap status and retire valid
                led_display = {7'b0, retire_halt, retire_trap, retire_valid};
            end
            
            2'b10: begin
                // Show current PC
                led_display = retire_pc[9:0];
            end
            
            2'b11: begin
                // Show destination register being written
                led_display = {retire_valid, retire_rd_waddr, 4'b0};
            end
            
            default: led_display = 10'h000;
        endcase
    end
    
    assign LEDR = led_display;

endmodule
