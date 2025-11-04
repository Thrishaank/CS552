module fetch #(parameter RESET_ADDR = 32'h00000000)(
    input i_clk, i_rst,
    //input [31:0] branch_target,  // Branch/jump target address ((replace with execute equivalent))
    //input branch_taken,          // Branch was taken (replace with execute equivalent)
    //input jump_taken,            // Jump occurred (replace with execute equivalent)
    input [31:0] i_imem_rdata,
    input stall,  // Stall signal from hazard detection (hold PC and instruction)
    output [31:0] o_imem_raddr,
    output [31:0] instruction,
    //output [31:0] pc_plus4,
    output reg [31:0] pc
);

    // TODO: Mux to take in branch and pc_plus_4, select btw if branch or jump occurs
    // TODO: Hold old pc, and instruction (stall)

    
    // TODO: Hold old pc, and instruction (stall) // DONE

    // Infers PC flop with active high reset and stall support
    always @(posedge i_clk) begin
        if (i_rst)
            pc <= RESET_ADDR;
        else if (!stall)  // Only update PC when not stalling
            pc <= next_pc;
        // When stall is high, PC holds its current value
    end

    // TODO: Mux to take in branch and pc_plus_4, select btw if branch or jump occurs //DONE
    // Mux: select between pc_plus4 (normal) or branch_target (when branch/jump taken)
    //wire [31:0] next_pc;
    //assign next_pc = (branch_taken | jump_taken) ? branch_target : pc_plus4;

    // increment pc by 4
    //assign pc_plus4 = pc + 32'h4; //MATTHEW ADDED IT IN EXECUTE BLOCK

    // Output the instruction read from memory
    assign instruction = i_imem_rdata;

    // set o_imem_raddr to current pc (so it can be used to fetch instruction in hart.v)
    assign o_imem_raddr = pc;

endmodule