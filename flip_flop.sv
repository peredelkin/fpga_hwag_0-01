
`ifndef FLIP_FLOP_SV
`define FLIP_FLOP_SV

module d_ff_wide #(parameter WIDTH=1) (d,clk,rst,ena,q);
input wire clk,rst,ena;
input wire [WIDTH-1:0] d;
output reg [WIDTH-1:0] q;
initial q <= 0;
always @(posedge clk,posedge rst) begin
    if(rst) begin
        q <= 0;
    end else begin
        if(ena) begin
            q <= d;
        end
    end
end
endmodule

//module d_ff_load_wide #(parameter WIDTH=1) (d,clk,rst,ena,ld,dld,q);
//endmodule

`endif
