
`ifndef MULT_DEMULT_SV
`define MULT_DEMULT_SV

//sel == 0:out <= dataa; sel == 1: out <= datab
module simple_multiplexer #(parameter WIDTH=1) (dataa,datab,sel,out);
input wire [WIDTH-1:0] dataa,datab;
input wire sel;
output reg [WIDTH-1:0] out;
always @(*) begin
    if(sel) begin
        out <= datab;
    end else begin
        out <= dataa;
    end
end
endmodule

module multiplexer #(parameter WIDTH=1,DEPTH=1) (addr,d,q);
localparam ADDR_WIDTH = $clog2(DEPTH);
input wire [ADDR_WIDTH-1:0] addr;
input wire [WIDTH-1:0] d [DEPTH-1:0];
output reg [WIDTH-1:0] q ;
always @(*) begin
	q <= d[addr];
end
endmodule

`endif
