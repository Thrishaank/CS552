module d_ff #(parameter WIDTH = 1, parameter RST_VAL = {WIDTH{1'b0}}) (
    input wire i_clk,
    input wire i_rst,
    input wire [WIDTH-1:0]  d,
    output reg [WIDTH-1:0] q
);
    always @(posedge i_clk) begin
        if (i_rst) q <= RST_VAL;
        else q <= d;
    end
endmodule