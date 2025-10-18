module fetch #(parameter RESET_ADDR = 32'h00000000)(
    input i_clk, i_rst,
    input [31:0] next_pc,
    input [31:0] i_imem_rdata,
    output [31:0] o_imem_raddr,
    output [31:0] instruction,
    output [31:0] pc_plus4,
    output reg [31:0] pc
);

    // Infers PC flop with active high reset
    always @(posedge i_clk) begin
        // infer pc reg
        if (i_rst)
            pc <= RESET_ADDR;
        else
            pc <= next_pc;
    end

    // increment pc by 4
    assign pc_plus4 = pc + 32'h4;

    // Output the instruction read from memory
    assign instruction = i_imem_rdata;

    // set o_imem_raddr to current pc (so it can be used to fetch instruction in hart.v)
    assign o_imem_raddr = pc;

endmodule