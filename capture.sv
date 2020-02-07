
`ifndef CAPTURE_SV
`define CAPTURE_SV

module pin_cnt_filter #(parameter WIDTH=1)
                        (d,clk,rst,filt_ena,out_ena,flt_val,q);
								
input wire d,clk,rst,filt_ena,out_ena;
input wire [WIDTH-1:0] flt_val;
wire dqxnor,cnt_ne_flt,cnt_e_flt;
output wire q;
xnor(dqxnor,d,q); //d not equal q
counter_compare #(WIDTH) cnt_comp(  .clk(clk),
                                    .ena(filt_ena & cnt_ne_flt),
                                    .rst(rst | dqxnor),
                                    .dtop(flt_val),
                                    .out_ne_top(cnt_ne_flt),
                                    .out_e_top(cnt_e_flt));
                                    
d_ff_wide #(1) d_ff(.d(d),.clk(clk),.rst(rst),.ena(out_ena & cnt_e_flt),.q(q));
endmodule

module pin_edge_gen(d,clk,rst,ena,rise0,rise1,fall0,fall1);

input wire d,clk,rst,ena;
output wire rise0,rise1,fall0,fall1;
wire q0,q1;

and(rise0,d,~q0);
and(rise1,q0,~q1);
and(fall0,~d,q0);
and(fall1,~q0,q1);

d_ff_wide #(1) d_ff0(	.d(d),
								.clk(clk),
								.rst(rst),
								.ena(ena),
								.q(q0));
								
d_ff_wide #(1) d_ff1(	.d(q0),
								.clk(clk),
								.rst(rst),
								.ena(ena),
								.q(q1));
endmodule


module capture_flt_edge_det_sel #(parameter WIDTH=1)
                  (d,clk,rst,filt_ena,out_ena,sel,flt_val,filtered,edge0,edge1);
						
input wire d,clk,rst,filt_ena,out_ena,sel;
input wire [WIDTH-1:0] flt_val;
output wire filtered,edge0,edge1;
wire rise0,rise1,fall0,fall1;
wire rise0_q,rise1_q,fall0_q,fall1_q;

pin_cnt_filter #(WIDTH) pin_filter (	.d(d),
													.clk(clk),
													.rst(rst),
													.filt_ena(filt_ena),
													.out_ena(out_ena),
													.flt_val(flt_val),
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
