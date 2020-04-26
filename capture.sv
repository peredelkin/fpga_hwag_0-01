`ifndef CAPTURE_SV
`define CAPTURE_SV

module hwag_vr_capture #(parameter WIDTH_FST=1,WIDTH_SND=1) (d,clk,rst,ena,out_ena,fst_val,snd_val,filtered,sel,edge0,edge1);
input wire d;
input wire clk;
input wire rst;
input wire ena;
input wire out_ena;
input wire [WIDTH_FST-1:0] fst_val;
input wire [WIDTH_SND-1:0] snd_val;
output wire filtered;
input wire sel;
output wire edge0,edge1;

wire cap_ena = (~filtered & (sel | out_ena) & ena) | (filtered & (~sel | out_ena) & ena);

d_ff_wide #(1) vr_cap	(	.d(d),
									.clk(clk),
									.rst(rst),
									.ena(cap_ena),
									.q(filtered));
									
d_ff_wide #(2) edge_gen	(	.d({filtered0,filtered}),
									.clk(clk),
									.rst(rst),
									.ena(ena),
									.q({filtered1,filtered0}));
									
and(rise0,filtered,~filtered0);
and(rise1,filtered0,~filtered1);

and(fall0,~filtered,filtered0);
and(fall1,~filtered0,filtered1);
									
simple_multiplexer #(2) edge_sel	(	.dataa({rise1,rise0}),
												.datab({fall1,fall0}),
												.sel(sel),
												.out({edge1,edge0}));

endmodule

module period_capture_3 #(parameter WIDTH = 1) (d,clk,rst,ena,q0,q1,q2);
input wire clk,rst,ena;
input wire [WIDTH-1:0] d;
output wire [WIDTH-1:0] q0;
output wire [WIDTH-1:0] q1;
output wire [WIDTH-1:0] q2;
d_ff_wide #(WIDTH) cap0(.d(d),.clk(clk),.rst(rst),.ena(ena),.q(q0));
d_ff_wide #(WIDTH) cap1(.d(q0),.clk(clk),.rst(rst),.ena(ena),.q(q1));
d_ff_wide #(WIDTH) cap2(.d(q1),.clk(clk),.rst(rst),.ena(ena),.q(q2));
endmodule

`endif
