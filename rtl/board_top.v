module board_top (
    input  wire        CLOCK_50,   // 50 MHz system clock
    input  wire [9:0]  SW,         // slide switches
    output wire [9:0]  LEDR        // red LEDs
);

    // Reset 

    wire rst_n = SW[9];            // change to ~SW[9] if active-low reset
    wire [31:0] pc;
    wire [31:0] instr;

    reg [31:0] rom [0:1023];       // 1024 words 

    initial begin
        $readmemh("../tests/prog.hex", rom);
    end

    // Word index from byte address 
    assign instr = rom[pc[11:2]];

    wire [31:0] dbg_result;        // value to show on LEDs (low 10 bits)

    hart #(
        .RESET_ADDR(32'h0000_0000)
    ) u_hart (
        .i_clk            (i_clk),
        .i_rst            (i_rst),
        .o_imem_raddr     (imem_addr),
        .i_imem_rdata     (imem_rdata),
//UNUESD
        .o_dmem_addr      (d_addr),
        .o_dmem_ren       (d_ren),
        .o_dmem_wen       (d_wen),
        .o_dmem_wdata     (d_wdata),
        .o_dmem_mask      (d_mask),
        .i_dmem_rdata     (d_rdata),

        // retire interface used to capture a1
        .o_retire_valid   (retire_valid),
        .o_retire_inst    (),               // unused 
        .o_retire_trap    (),               // unused 
        .o_retire_halt    (),               // unused 
        .o_retire_rs1_raddr (),
        .o_retire_rs2_raddr (),
        .o_retire_rs1_rdata (),
        .o_retire_rs2_rdata (),
        .o_retire_rd_waddr (retire_rd_waddr),
        .o_retire_rd_wdata (retire_rd_wdata),
        .o_retire_pc      (),               
        .o_retire_next_pc ()
    );

    // Show low 10 bits of dbg_result 
    assign LEDR = dbg_result[9:0];

endmodule
