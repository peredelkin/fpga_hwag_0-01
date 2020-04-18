
`ifndef CAPTURE_SV
`define CAPTURE_SV



module two_stage_filter #(parameter WIDTH_FST=1,WIDTH_SND=1)
						(d,clk,rst,fst_ena,snd_ena,out_ena,fst_val,snd_val,q);
input wire d,clk,rst,fst_ena,snd_ena,out_ena;
input wire	[WIDTH_FST-1:0] fst_val;
wire 			[WIDTH_FST-1:0] fst_out;
input wire	[WIDTH_SND-1:0] snd_val;
wire			[WIDTH_SND-1:0] snd_out;
output wire q;

localparam [WIDTH_SND-1:0] snd_zero_comp_dataa = 0;

xnor(rst_fst,d,q0);
counter #(WIDTH_FST) fst_cnt
                (.clk(clk),
					 .rst(rst | rst_fst),
					 .ena(fst_ena & fst_ne_val),
					 .data_out(fst_out));

compare #(WIDTH_FST) fst_val_comp
                (.dataa(fst_val),
					 .datab(fst_out),
					 .aeb(fst_e_val),
					 .aneb(fst_ne_val));
					 
d_ff_wide #(1) d_ff0 
					(.d(d),
					.clk(clk),
					.rst(rst),
					.ena(fst_ena & fst_e_val),
					.q(q0));

counter_reversible #(WIDTH_SND) snd_cnt
                (.clk(clk),
					 .rst(rst),
					 .ena(snd_ena & ((snd_ne_zero & !q0) | (snd_ne_val & q0))),
					 .rev(!q0),
					 .data_out(snd_out));
					 
compare #(WIDTH_SND) snd_zero_comp
                (.dataa(snd_zero_comp_dataa),
					 .datab(snd_out),
					 .aeb(snd_e_zero),
					 .aneb(snd_ne_zero));
					 
compare #(WIDTH_SND) snd_val_comp
                (.dataa(snd_val),
					 .datab(snd_out),
					 .aeb(snd_e_val),
					 .aneb(snd_ne_val));

rs_ff rs_ff0 	(.set(snd_e_val),
					.reset(snd_e_zero),
					.clk(clk),
					.rst(rst),
					.ena(out_ena),
					.q(q));
endmodule

module pin_edge_gen(d,clk,rst,ena,rise0,rise1,fall0,fall1);

input wire d,clk,rst,ena;
output wire rise0,rise1,fall0,fall1;
wire q0;

and(rise,d,~q0);
and(fall,~d,q0);

d_ff_wide #(5) edge_ff(	.d({d,rise,fall,rise0,fall0}),
								.clk(clk),
								.rst(rst),
								.ena(ena),
								.q({q0,rise0,fall0,rise1,fall1}));
endmodule


module capture_flt_edge_det_sel #(parameter WIDTH_FST=1,WIDTH_SND=1)
                  (d,clk,rst,fst_ena,snd_ena,out_ena,fst_val,snd_val,filtered,sel,edge0,edge1);
						
input wire	d,clk,rst,fst_ena,snd_ena,out_ena,sel;
input wire	[WIDTH_FST-1:0] fst_val;
input wire	[WIDTH_SND-1:0] snd_val;
output wire filtered,edge0,edge1;
wire rise0,rise1,fall0,fall1;
wire rise0_q,rise1_q,fall0_q,fall1_q;

two_stage_filter #(WIDTH_FST,WIDTH_SND) cnt_filter
						(.d(d),
						.clk(clk),
						.rst(rst),
						.fst_ena(fst_ena),
						.snd_ena(snd_ena),
						.out_ena(out_ena),
						.fst_val(fst_val),
						.snd_val(snd_val),
						.q(filtered));
													
pin_edge_gen pin_edge (	.d(filtered),
								.clk(clk),
								.rst(rst),
								.ena(out_ena),
								.rise0(rise0),
								.rise1(rise1),
								.fall0(fall0),
								.fall1(fall1));
								
simple_multiplexer #(2) edge_select(.dataa({rise0,rise1}),
												.datab({fall0,fall1}),
												.sel(sel),
												.out({edge0,edge1}));
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
