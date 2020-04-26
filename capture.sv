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

wire fst_counter_rst = ~(d ^ fst_flt_out);
wire cap_ena = (ena & ((~filtered & snd_counter_e_hi & (sel | out_ena)) | (filtered & snd_counter_e_lo & (~sel | out_ena))));
wire rise0 = (filtered & ~filtered0);
wire rise1 = (filtered0 & ~filtered1);
wire fall0 = (~filtered & filtered0);
wire fall1 = (~filtered0 & filtered1);

//1st stage
counter_compare #(WIDTH_FST) fst_counter
								(	.clk(clk),
									.ena(ena & fst_counter_ne_top),
									.rst(rst | fst_counter_rst),
									.dtop(fst_val),
									.out_e_top(fst_counter_e_top),
									.out_ne_top(fst_counter_ne_top));
									
d_ff_wide #(1) fst_flt
								(	.d(d),
									.clk(clk),
									.rst(rst),
									.ena(fst_counter_e_top),
									.q(fst_flt_out));
//1st stage end

//2nd stage
wire [WIDTH_SND-1:0] snd_counter_out;
wire snd_counter_ena = (ena & ((fst_flt_out & snd_counter_ne_hi) | (~fst_flt_out & snd_counter_ne_lo)));
localparam [WIDTH_SND-1:0] snd_lo = 0;
counter_reversible #(WIDTH_SND) snd_counter
								(	.clk(clk),
									.rst(rst),
									.ena(snd_counter_ena),
									.rev(~fst_flt_out),
									.data_out(snd_counter_out));

compare #(WIDTH_SND) snd_counter_hi
								(	.dataa(snd_counter_out),
									.datab(snd_val),
									.aeb(snd_counter_e_hi),
									.aneb(snd_counter_ne_hi));
									
compare #(WIDTH_SND) snd_counter_lo
								(	.dataa(snd_counter_out),
									.datab(snd_lo),
									.aeb(snd_counter_e_lo),
									.aneb(snd_counter_ne_lo));
//2nd stage end

d_ff_wide #(1) vr_cap	(	.d(fst_flt_out),
									.clk(clk),
									.rst(rst),
									.ena(cap_ena),
									.q(filtered));
									
d_ff_wide #(2) edge_gen	(	.d({filtered0,filtered}),
									.clk(clk),
									.rst(rst),
									.ena(ena),
									.q({filtered1,filtered0}));

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
