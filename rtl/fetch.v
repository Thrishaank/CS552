module(
    input clk, rst_n,
    input [31:0] new_pc,
    input [31:0] i_imem_rdata,
    output [31:0] read_addr,
    output [31:0] instruction
    output [31:0] next_pc;
    output reg [31:0] pc;

);

    always @(posedge clk, negedge rst_n) begin
        // infer pc reg
    end

    assign instruction = i_imem_rdata;



endmodule