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

module hwag(clk,cap_in,cap_out,led1_out,led2_out,comp_set_out);
input wire clk;
input wire cap_in;
output wire cap_out;

output wire led1_out = ~gap_found;
output wire led2_out = ~tcnt_e_top;

localparam PCNT_WIDTH = 24;
localparam TCNT_WIDTH = 8;
localparam HWASTWD = 4'd4;
localparam HWAMAXACR = 24'd3839;

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

//PCNT
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

//PCNT end

//PCNT_CAP
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

//PCNT_CAP end

//GAP_SEARCH
wire gap_found;
gap_search #(PCNT_WIDTH) gap_start_srch
										(	.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.gap(gap_found));
//GAP_SEARCH end

//PERIOD_CHECK
wire period_normal = (cap_less_max & cap_more_min);
period_normal_comp #(PCNT_WIDTH) cap_comp
										(	.min(24'd512),
											.max(24'd5592405),
											.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.less_max(cap_less_max),
											.more_min(cap_more_min));
//PERIOD_CHECK end

//HWAG_START
d_ff_wide #(1) d_ff_hwag_start
										(	.d(gap_found & period_normal & edge0),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(~hwag_start),
											.q(hwag_start));
//HWAG_START end

//TCNT
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
//TCNT end

// SCNT_TOP calc
wire [21:0] scnt_top;
shift_right #(22,4) scnt_top_calc
										(	.in(pcnt0_out[23:2]),
											.shift(HWASTWD),
											.out(scnt_top));
// SCNT_TOP calc end

// TCKC_TOP calc
wire [17:0] tckc_top;
assign tckc_top [1:0] = 2'b0;
shift_left #(16,4) tckc_top_calc
										(	.in(16'd1),
											.shift(HWASTWD),
											.out(tckc_top[17:2]));
// TCKC_TOP calc end

// TCKC actual top calc
wire [18:0] tckc_actial_top;
hwag_tckc_actual_top #(19) tckc_actial_top_calc
										(	.gap_point(gap_run_point),
											.tckc_top({1'b0,tckc_top}),
											.tckc_actial_top(tckc_actial_top));

// Tooth angle
wire [23:0] tooth_angle;
assign tooth_angle [1:0] = 2'b0;
shift_left #(22,4) acnt_tooth_calc
										(	.in({14'd0,tcnt_out}),
											.shift(HWASTWD),
											.out(tooth_angle[23:2]));
// Tooth angle end

// SCNT
wire [21:0] scnt_out;
and(scnt_ena,hwag_start,tckc_ne_top);
counter_compare #(22) scnt
										(	.clk(clk),
											.ena(scnt_ena),
											.rst(rst),
											.srst(scnt_e_top |  edge0),
											.dout(scnt_out),
											.dtop(scnt_top),
											.out_e_top(scnt_e_top));
// SCNT end

// TCKC
wire [18:0] tckc_out;
and(tckc_ena,scnt_ena,scnt_e_top);
counter_compare #(19) tckc
										(	.clk(clk),
											.ena(tckc_ena),
											.rst(rst),
											.srst(edge0),
											.dout(tckc_out),
											.dtop(tckc_actial_top),
											.out_ne_top(tckc_ne_top));
// TCKC end

// ACNT
d_ff_wide #(1) acnt_rst_ff
										(	.d(acnt_e_top),
											.clk(clk),
											.rst(~acnt_e_top),
											.ena(tckc_ena),
											.q(acnt_rst));

wire [23:0] acnt_out;
counter_compare #(24) acnt
										(	.clk(clk),
											.ena(tckc_ena),
											.rst(rst | acnt_rst),
										/*	.srst(tckc_ena & acnt_e_top),*/
											.sload(~hwag_start | edge1),
											.dload(tooth_angle),
											.dout(acnt_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt_e_top));
// ACNT end

//компараторы
output wire comp_set_out;
compare #(24) comp_set
										(	.dataa(acnt_out),
											.datab(24'd3776),
											.ageb(comp_set_out));

//компараторы

endmodule
//`endif

