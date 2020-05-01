`ifndef HWAG_CORE_SV
`define HWAG_CORE_SV

module hwag_core (clk,rst,ena,cap_in,cap_out,edge0,edge1,pcnt_e_top,period_normal,hwag_start,acnt2_ena,gap_run_point,pcnt0_out,tcnt_out,scnt_top);

localparam vr_cap_fst_val = 8'd7;
localparam vr_cap_snd_val = 8'd7;
localparam vr_cap_edge_sel = 1'b1;
localparam pcnt_dtop = 24'hFFFFFF;
localparam cap_comp_min = 24'd512;
localparam cap_comp_max = 24'd5592405;

localparam tcnt_dload = 8'd2;
localparam tcnt_dtop = 8'd57;
localparam step_width = 4'd4;
localparam no_gap_filt_val = 19'd45;
localparam gap_filt_val = 19'd134;
localparam acnt_top = 24'd3839;


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
output wire [23:0] pcnt0_out;
output wire [7:0] tcnt_out;
output wire [21:0] scnt_top;

assign gap_run_point = tcnt_e_top;
assign period_normal = (cap_less_max & cap_more_min);

wire [23:0] pcnt_out;
wire [23:0] pcnt1_out,pcnt2_out;

wire vr_cap_out_ena = ~hwag_start | window_filter_out;

hwag_vr_capture #(8,8) vr_cap (	.d(cap_in),
											.clk(clk),
											.rst(rst),
											.ena(ena),
											.out_ena(vr_cap_out_ena),
											.fst_val(vr_cap_fst_val),
											.snd_val(vr_cap_snd_val),
											.filtered(cap_out),
											.sel(vr_cap_edge_sel),
											.edge0(edge0),
											.edge1(edge1));

//PCNT
counter_compare #(24) pcnt
										(	.clk(clk),
											.ena(ena & pcnt_ne_top),
											.rst(rst),
											.srst(edge0),
											.dout(pcnt_out),
											.dtop(pcnt_dtop),
											.out_e_top(pcnt_e_top),
											.out_ne_top(pcnt_ne_top));

//PCNT end

//PCNT_CAP
wire pcnt_cap_ena = ena & edge0 & (~hwag_start | ~gap_run_point);
period_capture_3 #(24) pcnt_cap
										(	.d(pcnt_out),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(pcnt_cap_ena),
											.q0(pcnt0_out),
											.q1(pcnt1_out),
											.q2(pcnt2_out));

//PCNT_CAP end

//GAP_SEARCH
gap_search #(24) gap_start_srch
										(	.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.gap(gap_found));
//GAP_SEARCH end

//PERIOD_CHECK
period_normal_comp #(24) cap_comp
										(	.min(cap_comp_min),
											.max(cap_comp_max),
											.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.less_max(cap_less_max),
											.more_min(cap_more_min));
//PERIOD_CHECK end

//HWAG_START
wire hwag_start_trigger_ena = ena & ~hwag_start & gap_found & period_normal & edge0;
d_ff_wide #(1) hwag_start_trigger
										(	.d(1'b1),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(hwag_start_trigger_ena),
											.q(hwag_start));
//HWAG_START end

//TCNT
wire tcnt_ena = ena & hwag_start & edge0;
counter_compare #(8) tcnt
										(	.clk(clk),
											.ena(tcnt_ena),
											.rst(rst),
											.srst(tcnt_e_top & edge0),
											.sload(~hwag_start),
											.dload(tcnt_dload),
											.dout(tcnt_out),
											.dtop(tcnt_dtop),
											.out_e_top(tcnt_e_top));
//TCNT end

// SCNT_TOP calc
shift_right #(22,4) scnt_top_calc
										(	.in(pcnt0_out[23:2]),
											.shift(step_width),
											.out(scnt_top));
// SCNT_TOP calc end

// TCKC_TOP calc
wire [17:0] tckc_top;
assign tckc_top [1:0] = 2'b0;
shift_left #(16,4) tckc_top_calc
										(	.in(16'd1),
											.shift(step_width),
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
											.shift(step_width),
											.out(tooth_angle[23:2]));
// Tooth angle end

// SCNT
wire [21:0] scnt_out;
wire scnt_ena = ena & hwag_start & tckc_ne_top; 
counter_compare #(22) scnt
										(	.clk(clk),
											.ena(scnt_ena),
											.rst(rst),
											.srst(scnt_e_top | edge0),
											.dout(scnt_out),
											.dtop(scnt_top),
											.out_e_top(scnt_e_top));
// SCNT end

// TCKC
wire [18:0] tckc_out;
wire tckc_ena = scnt_ena & scnt_e_top;
counter_compare #(19) tckc
										(	.clk(clk),
											.ena(tckc_ena),
											.rst(rst),
											.srst(edge0),
											.dout(tckc_out),
											.dtop(tckc_actial_top),
											.out_ne_top(tckc_ne_top));
// TCKC end

// Window filter
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
											.ena(tckc_ena),
											.rst(rst),
											.srst(tckc_ena & acnt_e_top),
											.sload(~hwag_start | edge1),
											.dload(tooth_angle),
											.dout(acnt_out),
											.dtop(acnt_top),
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
											.dtop(acnt_top),
											.out_e_top(acnt2_e_top));
// ACNT2 end
endmodule

module hwag_coil_trigger(clk,rst,hwag_start,acnt_ena,acnt_data,charge_data,ignition_data,coil_out);
input wire clk;
input wire rst;
input wire hwag_start;
input wire acnt_ena;
input wire [23:0] acnt_data;
input wire [23:0] charge_data;
input wire [23:0] ignition_data;
output wire coil_out;


compare #(24) coil_update_comp
										(	.dataa(acnt_data),
											.datab(charge_data),
											.alb(acnt_l_charge));
											
wire coil_update = (acnt_l_charge & ((acnt_ena & acnt_l_current_charge) | ~hwag_start));									
wire [23:0] coil_charge_data;
d_ff_wide #(24) coil_charge_buffer
										(	.d(charge_data),
											.clk(clk),
											.rst(rst),
											.ena(coil_update),
											.q(coil_charge_data));
											
wire [23:0] coil_ignition_data;
d_ff_wide #(24) coil14_ignition_buffer
										(	.d(ignition_data),
											.clk(clk),
											.rst(rst),
											.ena(coil_update),
											.q(coil_ignition_data));
											
compare #(24) coil_charge_comp
										(	.dataa(acnt_data),
											.datab(coil_charge_data),
											.alb(acnt_l_current_charge),
											.ageb(coil_charge_out));
											
compare #(24) coil_ignition_comp
										(	.dataa(acnt_data),
											.datab(coil_ignition_data),
											.ageb(coil_ignition_out));

wire coil_trigger_d = coil_charge_out & ~coil_ignition_out;
d_ff_wide #(1) coil_trigger (	.d(coil_trigger_d),
											.clk(clk),
											.rst(rst | ~hwag_start),
											.ena(acnt_ena),
											.q(coil_out));
endmodule

`endif