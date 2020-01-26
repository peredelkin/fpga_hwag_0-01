
`ifndef MULT_DEMULT_SV
`define MULT_DEMULT_SV

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
