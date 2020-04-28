`ifndef HWAG_CORE_SV
`define HWAG_CORE_SV

module hwag_core (clk,rst,ena,cap_in,cap_out,edge0,edge1,pcnt_e_top,period_normal,hwag_start,acnt2_ena,gap_run_point,pcnt0_out,tcnt_out,scnt_top);

localparam PCNT_WIDTH = 24;
localparam TCNT_WIDTH = 8;
localparam HWASTWD = 4'd4;
localparam HWAMAXACR = 24'd3839;

input wire clk;
input wire rst;
input wire ena;
input wire cap_in;
output wire cap_out;
output wire edge0;
output wire edge1;
output wire pcnt_e_top;
output wire period_normal;
output wire hwag_start;
output wire acnt2_ena;
output wire gap_run_point;
output wire [PCNT_WIDTH-1:0] pcnt0_out;
output wire [TCNT_WIDTH-1:0] tcnt_out;
output wire [21:0] scnt_top;

assign gap_run_point = tcnt_e_top;
assign period_normal = (cap_less_max & cap_more_min);
wire [PCNT_WIDTH-1:0] pcnt_out;
wire [PCNT_WIDTH-1:0] pcnt1_out,pcnt2_out;

hwag_vr_capture #(8,8) vr_cap (	.d(cap_in),
											.clk(clk),
											.rst(rst),
											.ena(ena),
											.out_ena(~hwag_start | window_filter_out),
											.fst_val(8'd7),
											.snd_val(8'd7),
											.filtered(cap_out),
											.sel(1'b1),
											.edge0(edge0),
											.edge1(edge1));

//PCNT
counter_compare #(PCNT_WIDTH) pcnt
										(	.clk(clk),
											.ena(ena & pcnt_ne_top),
											.rst(rst),
											.srst(edge0),
											.dout(pcnt_out),
											.dtop(24'hFFFFFF),
											.out_e_top(pcnt_e_top),
											.out_ne_top(pcnt_ne_top));

//PCNT end

//PCNT_CAP
period_capture_3 #(PCNT_WIDTH) pcnt_cap
										(	.d(pcnt_out),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(ena & edge0 & (~hwag_start | ~gap_run_point)),
											.q0(pcnt0_out),
											.q1(pcnt1_out),
											.q2(pcnt2_out));

//PCNT_CAP end

//GAP_SEARCH
gap_search #(PCNT_WIDTH) gap_start_srch
										(	.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.gap(gap_found));
//GAP_SEARCH end

//PERIOD_CHECK
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
											.ena(ena & ~hwag_start),
											.q(hwag_start));
//HWAG_START end

//TCNT
counter_compare #(TCNT_WIDTH) tcnt
										(	.clk(clk),
											.ena(ena & hwag_start & edge0),
											.rst(rst),
											.srst(tcnt_e_top & edge0),
											.sload(~hwag_start),
											.dload(8'd2),
											.dout(tcnt_out),
											.dtop(8'd57),
											.out_e_top(tcnt_e_top));
//TCNT end

// SCNT_TOP calc
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
// TCKC actual top calc end

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
											.ena(ena & scnt_ena),
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
											.ena(ena & tckc_ena),
											.rst(rst),
											.srst(edge0),
											.dout(tckc_out),
											.dtop(tckc_actial_top),
											.out_ne_top(tckc_ne_top));
// TCKC end

// Window filter
wire [18:0] no_gap_filt_val = 19'd45;
wire [18:0] gap_filt_val = 19'd134;
wire [18:0] current_filt_val;
simple_multiplexer #(19) window_filter_sel 
                                        (   .dataa(no_gap_filt_val),
                                            .datab(gap_filt_val),
                                            .sel(gap_run_point),
                                            .out(current_filt_val));

compare #(19) window_filter_comp
                                        (   .dataa(tckc_out),
                                            .datab(current_filt_val),
                                            .ageb(window_filter_out));
// Window filter end

// ACNT
wire [23:0] acnt_out;
counter_compare #(24) acnt
										(	.clk(clk),
											.ena(ena & tckc_ena),
											.rst(rst),
											.srst(tckc_ena & acnt_e_top),
											.sload(~hwag_start | edge1),
											.dload(tooth_angle),
											.dout(acnt_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt_e_top));
// ACNT end

// ACNT to ACNT2 interface
wire [23:0] acnt2_out;
compare #(24) acnt2_ena_comp
										(	.dataa(acnt2_out),
											.datab(acnt_out),
											.aeb(acnt2_e_acnt));
                                
d_ff_wide #(1) d_ff_acnt2_count_div2
										(	.d(~acnt2_ena),
											.clk(clk),
											.rst(rst | acnt2_e_acnt),
											.ena(ena & hwag_start),
											.q(acnt2_ena));
// ACNT to ACNT2 interface

// ACNT2
counter_compare #(24) acnt2
										(	.clk(clk),
											.ena(ena & acnt2_ena),
											.rst(rst),
											.srst(acnt2_ena & acnt2_e_top),
											.sload(~hwag_start),
											.dload(acnt_out),
											.dout(acnt2_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt2_e_top));
// ACNT2 end
endmodule

`endif