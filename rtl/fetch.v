module fetch #(parameter RESET_ADDR = 32'h00000000)(
    input i_clk, i_rst,
    input [31:0] new_pc,  // Branch/jump target address ((replace with execute equivalent))
    input branch_taken, // From execute stage (indicates if branch/jump is taken)
    input [31:0] i_imem_rdata,
    input stall,  // Stall signal from hazard detection (hold PC and instruction)
    output [31:0] o_imem_raddr,
    output [31:0] instruction,
    output [31:0] pc
);

    wire [31:0] next_pc;
    reg [31:0] i_pc;

    // Mux: select between pc_plus4 (normal) or branch_target (when branch/jump taken)
    assign next_pc = branch_taken ? new_pc : pc + 4;

    // Infers PC flop with active high reset and stall support
    always @(posedge i_clk) begin
        if (i_rst)
            i_pc <= RESET_ADDR;
        else if (!stall)    // Only update PC when not stalling
            i_pc <= next_pc;  
    end

    assign pc = i_pc;

    // Output the instruction read from memory
    assign instruction = i_imem_rdata;

    // set o_imem_raddr to current pc (so it can be used to fetch instruction in hart.v)
    assign o_imem_raddr = pc;

endmodule