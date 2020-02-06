`ifndef BIT_OPERATION_V
`define BIT_OPERATION_V

module shift_right #(parameter WIDTH=1,parameter SHIFT_WIDTH=1)
            (in,shift,out);
input wire [WIDTH-1:0] in;
input wire [SHIFT_WIDTH-1:0] shift;
output reg [WIDTH-1:0] out;
always @(*) begin
	out <= in >> shift;
end
endmodule

module shift_left #(parameter WIDTH=1,parameter SHIFT_WIDTH=1)
            (in,shift,out);
input wire [WIDTH-1:0] in;
input wire [SHIFT_WIDTH-1:0] shift;
output reg [WIDTH-1:0] out;
always @(*) begin
	out <= in << shift;
end
endmodule 

`endif
