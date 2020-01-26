
`ifndef BUFFER_SV
`define BUFFER_SV

module buffer_z #(parameter WIDTH=1) (ena,d,q);
input wire ena;
input wire [WIDTH-1:0] d;
output reg [WIDTH-1:0] q;
always @(*) begin
	if(ena) begin
		q <= d;
	end
	else begin
		q <= 'bZ;
	end
end
endmodule

`endif
