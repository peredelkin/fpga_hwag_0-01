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
`include "spi.sv"
`include "crc8.sv"
`include "spi_protocol.sv"

module hwag(clk,nrst,cap_in,cap_out,led1_out,led2_out,coil14_out,coil23_out,spi_si,spi_so,spi_sck,spi_ss);
input wire clk;
input wire nrst;
wire rst = ~nrst;
input wire cap_in;
output wire cap_out;

output wire led1_out;
output wire led2_out;
assign led1_out = spi_crc_rx_equal;
assign led2_out = ~gap_run_point;

localparam PCNT_WIDTH = 24;
localparam TCNT_WIDTH = 8;
localparam HWASTWD = 4'd4;
localparam HWAMAXACR = 24'd3839;

input wire spi_si;
output wire spi_so;
input wire spi_sck;
input wire spi_ss;

//SPI
wire [7:0] spi_bus_out;
wire [7:0] spi_crc_rx_out;

//Spi data frame
// [CMD8]:[ADDR8]:[DATA32]:[CRC8]
wire [7:0] spi_hwag_cmd;
wire [7:0] spi_hwag_addr;
wire [31:0] spi_hwag_data;
//Spi data frame end

hwag_spi_rx_data_frame hwag_spi_rx_frame
										(	.clk(clk),
											.rst(rst),
											.spi_ss(spi_ss),
											.spi_rx(spi_rx),
											.spi_bus_out(spi_bus_out),
											.spi_crc_rx_out(spi_crc_rx_out),
											.spi_hwag_cmd(spi_hwag_cmd),
											.spi_hwag_addr(spi_hwag_addr),
											.spi_hwag_data(spi_hwag_data),
											.spi_crc_rx_equal(spi_crc_rx_equal),
											.spi_ss_rise(spi_ss_rise));

spi_slave spi_slave0
										(	.spi_in(spi_si),
											.spi_out(spi_so),
											.spi_clk(spi_sck),
											.spi_ss(spi_ss),
											.clk(clk),
											.rst(rst),
											.ena(1'b1),
											.bus_in(8'd0),
											.bus_out(spi_bus_out),
											.crc_rx_out(spi_crc_rx_out),
											.tx(spi_tx),
											.rx(spi_rx));
//SPI end

//Spi addr decoder
wire [15:0] spi_addr_msb_decoder_out;
wire [15:0] spi_addr_lsb_decoder_out;
decoder_4_16 spi_addr_msb_decoder
										(	.in(spi_hwag_addr[7:4]),
											.out(spi_addr_msb_decoder_out));
											
decoder_4_16 spi_addr_lsb_decoder
										(	.in(spi_hwag_addr[3:0]),
											.out(spi_addr_lsb_decoder_out));

//Spi addr decoder end

//Data registers
wire ignition_angle_0_ena = spi_addr_msb_decoder_out[0] & spi_addr_lsb_decoder_out[1] & spi_crc_rx_equal & spi_ss_rise;
wire [23:0] ignition_angle_0_out;
d_ff_wide #(24) ignition_angle_0
										(	.d(spi_hwag_data[23:0]),
											.clk(clk),
											.rst(rst),
											.ena(ignition_angle_0_ena),
											.q(ignition_angle_0_out));
//Data registers end

wire hwag_start;
wire edge0,edge1;
hwag_vr_capture #(8,8) vr_cap (	.d(cap_in),
											.clk(clk),
											.rst(rst),
											.ena(1'b1),
											.out_ena(~hwag_start | window_filter_out),
											.fst_val(8'd7),
											.snd_val(8'd7),
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
											.srst(edge0),
											.sload(1'b0),
											.dload(24'd0),
											.dout(pcnt_out),
											.dtop(24'hFFFFFF),
											.out_e_top(pcnt_e_top),
											.out_ne_top(pcnt_ne_top));

//PCNT end

//PCNT_CAP
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
											.ena(tckc_ena),
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
											.ena(hwag_start),
											.q(acnt2_ena));
// ACNT to ACNT2 interface

// ACNT2
counter_compare #(24) acnt2
										(	.clk(clk),
											.ena(acnt2_ena),
											.rst(rst),
											.srst(acnt2_ena & acnt2_e_top),
											.sload(~hwag_start),
											.dload(acnt_out),
											.dout(acnt2_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt2_e_top));
// ACNT2 end

// Slave ACNT
wire [23:0] acnt3_out;
counter_compare #(24) acnt3
										(	.clk(clk),
											.ena(acnt2_ena),
											.rst(rst),
											.srst(acnt2_ena & acnt3_e_top),
											.sload(~hwag_start),
											.dload(24'd2752),
											.dout(acnt3_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt3_e_top));

wire [23:0] acnt4_out;
counter_compare #(24) acnt4
										(	.clk(clk),
											.ena(acnt2_ena),
											.rst(rst),
											.srst(acnt2_ena & acnt4_e_top),
											.sload(~hwag_start),
											.dload(24'd832),
											.dout(acnt4_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt4_e_top));
// Slave ACNT

//Instant rpm calc
wire [23:0] instant_rpm_remainder;
wire [23:0] instant_rpm_result;
wire instant_rpm_rdy;
integer_division #(24) instant_rpm
                                        (   .clk(clk),
                                            .rst(rst),
                                            .start(~edge1),
                                            .dividend(24'h2FAF08),
                                            .divider({4'd0,pcnt0_out[23:4]}),
                                            .remainder(instant_rpm_remainder),
                                            .result(instant_rpm_result),
                                            .rdy(instant_rpm_rdy));
//Instant rpm calc end

// Dwell angle calc
wire [23:0] dwell_angle_remainder;
wire [23:0] dwell_angle_result;
wire dwell_angle_rdy;
integer_division #(24) dwell_angle
										(	.clk(clk),
											.rst(rst),
											.start(~edge1),
											.dividend(24'd50000),
											.divider({2'd0,scnt_top}),
											.remainder(dwell_angle_remainder),
											.result(dwell_angle_result),
											.rdy(dwell_angle_rdy));
											
wire [23:0] dwell_angle_out;
d_ff_wide #(24) d_ff_dwell_time
										(	.d(dwell_angle_result),
											.clk(clk),
											.rst(rst),
											.ena(edge0 & dwell_angle_rdy),
											.q(dwell_angle_out));
// Dwell angle calc end

// Coil set point calc
wire [23:0] coil_set_point_out;
integer_subtraction #(24) coil_set_point 
										(	.minuend(ignition_angle_0_out),
											.subtrahend(dwell_angle_out),
											.result(coil_set_point_out));

// Coil set point calc end

// shadow registers
wire [23:0] set14_shadow_register_out;
compare #(24) set14_point_shadow_comp
										(	.dataa(acnt3_out),
											.datab(coil_set_point_out),
											.alb(set14_point_shadow_comp_out));
d_ff_wide #(24) set14_shadow_register
										(	.d(coil_set_point_out),
											.clk(clk),
											.rst(rst),
											.ena(edge1 & set14_point_shadow_comp_out),
											.q(set14_shadow_register_out));

wire [23:0] set23_shadow_register_out;
compare #(24) set23_point_shadow_comp
										(	.dataa(acnt4_out),
											.datab(coil_set_point_out),
											.alb(set23_point_shadow_comp_out));
d_ff_wide #(24) set23_shadow_register
										(	.d(coil_set_point_out),
											.clk(clk),
											.rst(rst),
											.ena(edge1 & set23_point_shadow_comp_out),
											.q(set23_shadow_register_out));
//compare #(24) reset_point_shadow_comp
//                (dataa,datab,aeb,agb,alb,aneb,ageb,aleb);
//d_ff_wide #(parameter WIDTH=1) (d,clk,rst,ena,q);
// shadow registers end

//компараторы
output wire coil14_out;
compare #(24) comp14_set
										(	.dataa(acnt3_out),
											.datab(set14_shadow_register_out),
											.aeb(comp14_set_out));

compare #(24) comp14_reset
										(	.dataa(acnt3_out),
											.datab(ignition_angle_0_out),
											.aeb(comp14_reset_out));

d_ff_wide #(1) ff_coil14
										(	.d(1'b1),
											.clk(clk),
											.rst(comp14_reset_out | ~hwag_start),
											.ena(comp14_set_out),
											.q(coil14_out));
											
output wire coil23_out;
compare #(24) comp23_set
										(	.dataa(acnt4_out),
											.datab(set23_shadow_register_out),
											.aeb(comp23_set_out));

compare #(24) comp23_reset
										(	.dataa(acnt4_out),
											.datab(ignition_angle_0_out),
											.aeb(comp23_reset_out));

d_ff_wide #(1) ff_coil23
										(	.d(1'b1),
											.clk(clk),
											.rst(comp23_reset_out | ~hwag_start),
											.ena(comp23_set_out),
											.q(coil23_out));
//компараторы

endmodule
//`endif

