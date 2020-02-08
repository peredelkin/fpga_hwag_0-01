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

module hwag(clk,rst,ssram_we,ssram_re,ssram_addr,ssram_data,vr_in,vr_out,hwagif,hwag_start,acnt2_e_top);
input wire clk,rst;
output wire vr_out;
output wire hwag_start;
output wire hwagif;
output wire acnt2_e_top;

// ssram interface
input wire ssram_we,ssram_re;
input wire [7:0] ssram_addr;
inout wire [15:0] ssram_data;
wire [15:0] ssram_row;
wire [15:0] ssram_column;
wire [15:0] ssram_out [63:0];

decoder_8_row_column ssram_decoder (.in(ssram_addr),.row(ssram_row),.column(ssram_column));

// hwag registers
// ssram
ssram_256 #(16,64) ssram (	.clk(clk),
									.rst(rst),
									.we(ssram_we),
									.re(ssram_re),
									.row(ssram_row),
									.column(ssram_column),
									.data(ssram_data),
									.out(ssram_out));
// ssram end

//
wire [15:0] HWASFCR		=					 ssram_out[0];
wire [31:0] HWAMINCPR	= {ssram_out[2],ssram_out[1]};
wire [31:0] HWAMAXCPR	= {ssram_out[4],ssram_out[3]};
wire [15:0] HWATHNB		=					 ssram_out[5];
wire [15:0] HWASTWD		=					 ssram_out[6];
wire [31:0] HWAATOP		= {ssram_out[8],ssram_out[7]};
wire [31:0] HWAATOP1		={ssram_out[10],ssram_out[9]};
//

//
wire [15:0] HWAGCSCR0;
wire HWAGCSR0_addr	= ssram_row[4] & ssram_column[0];
wire HWAGCCR0_addr	= ssram_row[4] & ssram_column[1];

wire [15:0] HWAIESCR;
wire HWAIESR_addr		= ssram_row[4] & ssram_column[2];
wire HWAIECR_addr		= ssram_row[4] & ssram_column[3];

wire [15:0] HWAIFR;
wire HWAIFR_addr		= ssram_row[4] & ssram_column[4];

wire [23:0] HWAPCNT1;
wire HWAPCNT1L_addr	= ssram_row[4] & ssram_column[5];
wire HWAPCNT1H_addr	= ssram_row[4] & ssram_column[6];

wire [7:0] HWATHVL;
wire HWATHVL_addr		= ssram_row[4] & ssram_column[7];
//

// Hwag Global Control Set/Clear Register
wire HWAGCSCR0_CAPE = HWAGCSCR0[0];
wire HWAGCSCR0_EDGES = HWAGCSCR0[1];
wire HWAGCSCR0_SFLTE = HWAGCSCR0[2];
ssram_bsrr #(16) HWAGCSCR0_bsrr (.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.bsr_ena(HWAGCSR0_addr),
										.brr_ena(HWAGCCR0_addr),
										.we(ssram_we),
										.re(ssram_re),
										.bsr_q(HWAGCSCR0));

// Hwag Interrupt Enable Set/Clear Register
ssram_bsrr #(16) HWAIER_bsrr (.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.bsr_ena(HWAIESR_addr),
										.brr_ena(HWAIECR_addr),
										.we(ssram_we),
										.re(ssram_re),
										.bsr_q(HWAIESCR));
// Hwag Interrupt Flag Register
wire [15:0] HWAIF;
assign HWAIF[0] = vr_edge_0;
assign HWAIF[1] = pcnt_ovf;
assign HWAIF[2] = gap_drn_gap_point_if;
assign HWAIF[3] = gap_drn_normal_tooth_if;
ssram_ifr #(16) HWAIFR_ifr (	.flag(HWAIF & HWAIESCR),
										.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.frr_ena(HWAIFR_addr),
										.we(ssram_we),
										.re(ssram_re),
										.fsr_q(HWAIFR));
										
assign hwagif = 	HWAIFR[15] | HWAIFR[14] | HWAIFR[13] | HWAIFR[12] |
						HWAIFR[11] | HWAIFR[10] | HWAIFR[9]  | HWAIFR[8]  |
						HWAIFR[7]  | HWAIFR[6]  | HWAIFR[5]  | HWAIFR[4]  |
						HWAIFR[3]  | HWAIFR[2]  | HWAIFR[1]  | HWAIFR[0];
// hwag registers end
// ssram interface end

// Variable Reluctance Sensor input
input wire vr_in;
wire vr_edge_0,vr_edge_1;
capture_flt_edge_det_sel #(16) vr_filter (	.d(vr_in),
															.clk(clk),
															.rst(rst),
															.filt_ena(HWAGCSCR0_SFLTE),
															.out_ena(HWAGCSCR0_CAPE),
															.sel(HWAGCSCR0_EDGES),
															.flt_val(HWASFCR),
															.filtered(vr_out),
															.edge0(vr_edge_0),
															.edge1(vr_edge_1));

// Variable Reluctance Sensor input end

// PCNT
wire pcnt_ovf;
wire [23:0] HWAPCNT;
counter_compare #(24) pcnt (	.clk(clk),
										.ena(HWAGCSCR0_CAPE),
										.rst(rst | ~HWAGCSCR0_CAPE),
										.srst(vr_edge_0),
										.dout(HWAPCNT),
										.dtop(24'hFFFFFF),
										.out_e_top(pcnt_ovf));
// PCNT end

// Last three periods
wire [23:0] pcap1,pcap2;
wire gap_run_point = tcnt_e_top;
period_capture_3 #(24) pcap (	.d(HWAPCNT),
										.clk(clk),
										.rst(rst | ~HWAGCSCR0_CAPE),
										.ena(HWAGCSCR0_CAPE & vr_edge_0 & (~hwag_start | ~gap_run_point)),
										.q0(HWAPCNT1),
										.q1(pcap1),
										.q2(pcap2));

buffer_z #(16) pcap0_read_l (	.ena(HWAPCNT1L_addr & ssram_re),
										.d(HWAPCNT1[15:0]),
										.q(ssram_data));
buffer_z #(16) pcap0_read_h (	.ena(HWAPCNT1H_addr & ssram_re),
										.d({8'b0,HWAPCNT1[23:16]}),
										.q(ssram_data));
// Last three periods end

// Period check
wire pcap_l_max,pcap_g_min;
period_normal #(24) pnormal (	.min(HWAMINCPR[23:0]),
										.max(HWAMAXCPR[23:0]),
										.cap0(HWAPCNT1),
										.cap1(pcap1),
										.cap2(pcap2),
										.less_max(pcap_l_max),
										.more_min(pcap_g_min));

// Period check end

// GAP search
wire gap_search_gap;
gap_search #(24) gap_srch (.cap0(HWAPCNT1),
									.cap1(pcap1),
									.cap2(pcap2),
									.gap(gap_search_gap));
// GAP search end

// HWAG start/stop trigger
d_ff_wide #(1) hwag_start_ff (.d(pcap_g_min & pcap_l_max & gap_search_gap & vr_edge_0),
										.clk(clk),
										.rst(rst | ~HWAGCSCR0_CAPE),
										.ena(~hwag_start),
										.q(hwag_start));
// HWAG start/stop trigger end

// TCNT
counter_compare #(8) tcnt( .clk(clk),
                           .ena(hwag_start & vr_edge_0),
                           .rst(rst),
                           .srst(tcnt_e_top & vr_edge_0),
                           .sload(HWATHVL_addr & ssram_we),
                           .dload(ssram_data[7:0]),
                           .dout(HWATHVL),
                           .dtop(HWATHNB[7:0]),
                           .out_e_top(tcnt_e_top));

buffer_z #(16) tcnt_read(	.ena(HWATHVL_addr & ssram_re),
									.d({8'd0,HWATHVL}),
									.q(ssram_data));
// TCNT end

// GAP run check
wire gap_drn_gap_point = hwag_start & gap_run_found & gap_run_point;
wire gap_drn_gap_point_if = gap_drn_gap_point & vr_edge_0;
wire gap_drn_normal_tooth = hwag_start & gap_run_found & ~gap_run_point;
wire gap_drn_normal_tooth_if = gap_drn_normal_tooth & vr_edge_0;
gap_run_check #(24) gaprun(	.cap0(HWAPCNT1),
										.pcnt(HWAPCNT),
										.gap(gap_run_found));
// GAP run check end

//==========================================================================

// SCNT top calc (fixed)
wire [21:0] scnt_top;
shift_right #(22,4) scnt_top_calc(	.in(HWAPCNT1[23:2]),
												.shift(HWASTWD[3:0]),
												.out(scnt_top));
// SCNT top calc end

// TCKC top calc
wire [17:0] tckc_top;
assign tckc_top [1:0] = 2'b0;
shift_left #(16,4) tckc_top_calc(.in(16'd1),
											.shift(HWASTWD[3:0]),
											.out(tckc_top[17:2]));
// TCKC top calc end

// TCKC actual top calc
wire [18:0] tckc_actial_top;
//wire [18:0] tckc_actial_top_2;
hwag_tckc_actual_top #(19) tckc_actial_top_calc(.gap_point(gap_run_point),
																.tckc_top({1'b0,tckc_top}),
																.tckc_actial_top(tckc_actial_top));

// Tooth angle
wire [23:0] tooth_angle;
assign tooth_angle [1:0] = 2'b0;
shift_left #(22,4) acnt_tooth_calc(	.in({14'd0,HWATHVL}),
												.shift(HWASTWD[3:0]),
												.out(tooth_angle[23:2]));
// Tooth angle end

// SCNT
wire [21:0] scnt_out;
and(scnt_ena,hwag_start,tckc_ne_top);
counter_compare #(22) scnt( .clk(clk),
                            .ena(scnt_ena),
                            .rst(rst),
									 .srst(scnt_e_top |  vr_edge_0),
                            .dout(scnt_out),
                            .dtop(scnt_top),
                            .out_e_top(scnt_e_top));
// SCNT end

// TCKC
wire [18:0] tckc_out;
and(tckc_ena,scnt_ena,scnt_e_top);
counter_compare #(19) tckc (.clk(clk),
                            .ena(tckc_ena),
                            .rst(rst),
									 .srst(vr_edge_0),
                            .dout(tckc_out),
                            .dtop(tckc_actial_top),
                            .out_ne_top(tckc_ne_top));
// TCKC end

// ACNT
wire [23:0] acnt_out;
counter_compare #(24) acnt (.clk(clk),
                            .ena(tckc_ena),
                            .rst(rst),
									 .srst(tckc_ena & acnt_e_top),
                            .sload(~hwag_start | vr_edge_1),
                            .dload(tooth_angle),
                            .dout(acnt_out),
									 .dtop(HWAATOP[23:0]),
									 .out_e_top(acnt_e_top));
// ACNT end

// ACNT to ACNT2 interface
wire [23:0] acnt2_out;
compare #(24) acnt2_ena_comp(   .dataa(acnt2_out),
                                .datab(acnt_out),
                                .aneb(acnt2_ne_acnt));
                                
d_ff_wide #(1) d_ff_acnt2_count_div2 (	.d(~acnt2_count_div2),
													.clk(clk),
													.rst(rst),
													.ena(acnt2_ne_acnt),
													.q(acnt2_count_div2));
// ACNT to ACNT2 interface

// ACNT2
counter_compare #(24) acnt2 (   .clk(clk),
                                .ena(acnt2_count_div2 & acnt2_ne_acnt),
                                .rst(rst | acnt2_ovf),
										  .srst(acnt2_count_div2 & acnt2_ne_acnt & acnt2_e_top),
                                .sload(~hwag_start),
                                .dload(acnt_out),
                                .dout(acnt2_out),
                                .dtop(HWAATOP[23:0]),
                                .out_e_top(acnt2_e_top));
// ACNT2 end

endmodule

//`endif

