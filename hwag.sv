//`ifndef HWAG_SV
//`define HWAG_SV

`include "buffer.sv"
`include "capture.sv"
`include "decoder.sv"
`include "flip_flop.sv"
`include "memory.sv"
`include "mult_demult.sv"
`include "comparsion.sv"
`include "counting.sv"
`include "bit_operation.sv"
`include "math.sv"

module hwag(clk,cap_in,cap_out,led1_out,led2_out);
input wire clk;
input wire cap_in;
output wire cap_out;

output wire led1_out = ~gap_found;
output wire led2_out = ~tcnt_e_top;

localparam PCNT_WIDTH = 24;
localparam TCNT_WIDTH = 8;

wire edge0,edge1;
capture_flt_edge_det_sel #(4,10) vr_filter 
										(	.d(cap_in),
											.clk(clk),
											.rst(rst),
											.fst_ena(1'b1),
											.snd_ena(1'b1),
											.out_ena(1'b1),
											.fst_val(4'd7),
											.snd_val(10'd127),
											.filtered(cap_out),
											.sel(1'b1),
											.edge0(edge0),
											.edge1(edge1));

wire [PCNT_WIDTH-1:0] pcnt_out;									
counter_compare #(PCNT_WIDTH) pcnt
										(	.clk(clk),
											.ena(pcnt_ne_top),
											.rst(rst),
											.srst(edge1),
											.sload(1'b0),
											.dload(24'd0),
											.dout(pcnt_out),
											.dtop(24'hFFFFFF),
											.out_e_top(pcnt_e_top),
											.out_ne_top(pcnt_ne_top));

wire hwag_start;
wire gap_run_point = tcnt_e_top;
wire [PCNT_WIDTH-1:0] pcnt0_out,pcnt1_out,pcnt2_out;
period_capture_3 #(PCNT_WIDTH) pcnt_cap
										(	.d(pcnt_out),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(edge0 & (~hwag_start | ~gap_run_point)),
											.q0(pcnt0_out),
											.q1(pcnt1_out),
											.q2(pcnt2_out));

wire gap_found;
gap_search #(PCNT_WIDTH) gap_start_srch
										(	.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.gap(gap_found));

wire period_normal = (cap_less_max & cap_more_min);
period_normal_comp #(PCNT_WIDTH) cap_comp
										(	.min(24'd512),
											.max(24'd5592405),
											.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.less_max(cap_less_max),
											.more_min(cap_more_min));


d_ff_wide #(1) d_ff_hwag_start
										(	.d(gap_found & period_normal & edge0),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(~hwag_start),
											.q(hwag_start));
											
// TCNT
d_ff_wide #(1) tcnt_rst_ff
										(	.d(tcnt_e_top),
											.clk(clk),
											.rst(~tcnt_e_top),
											.ena(edge0),
											.q(tcnt_rst));

wire [TCNT_WIDTH-1:0] tcnt_out;
counter_compare #(TCNT_WIDTH) tcnt
										(	.clk(clk),
											.ena(hwag_start & edge0),
											.rst(rst | tcnt_rst),
										/*	.srst(tcnt_e_top & edge0),*/
											.sload(~hwag_start),
											.dload(8'd2),
											.dout(tcnt_out),
											.dtop(8'd57),
											.out_e_top(tcnt_e_top));

endmodule
//`endif

