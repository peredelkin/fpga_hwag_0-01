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
`include "hwag_base.sv"

module hwag(clk,nrst,cap_in,cap_out,led1_out,led2_out,coil14_out,coil23_out,spi_si,spi_so,spi_sck,spi_ss);
input wire clk;
input wire nrst;
wire rst = ~nrst;
input wire cap_in;
output wire cap_out;

output wire led1_out;
output wire led2_out;

output wire coil14_out;
output wire coil23_out;

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

wire [PCNT_WIDTH-1:0] pcnt0_out;
wire [TCNT_WIDTH-1:0] tcnt_out;
wire [21:0] scnt_top;
hwag_core hwag_core0				(	.clk(clk),
											.rst(rst),
											.ena(1'b1),
											.cap_in(cap_in),
											.cap_out(cap_out),
											.edge0(edge0),
											.edge1(edge1),
											.pcnt_e_top(pcnt_e_top),
											.period_normal(period_normal),
											.hwag_start(hwag_start),
											.acnt2_ena(acnt2_ena),
											.gap_run_point(gap_run_point),
											.pcnt0_out(pcnt0_out),
											.tcnt_out(tcnt_out),
											.scnt_top(scnt_top));

// Slave ACNT
wire [23:0] acnt3_out;
wire acnt3_srst = acnt2_ena & acnt3_e_top;
counter_compare #(24) acnt3
										(	.clk(clk),
											.ena(acnt2_ena),
											.rst(rst),
											.srst(acnt3_srst),
											.sload(~hwag_start),
											.dload(24'd2752),
											.dout(acnt3_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt3_e_top));

wire [23:0] acnt4_out;
wire acnt4_srst = acnt2_ena & acnt4_e_top;
counter_compare #(24) acnt4
										(	.clk(clk),
											.ena(acnt2_ena),
											.rst(rst),
											.srst(acnt4_srst),
											.sload(~hwag_start),
											.dload(24'd832),
											.dout(acnt4_out),
											.dtop(HWAMAXACR),
											.out_e_top(acnt4_e_top));
// Slave ACNT

//Instant rpm calc
wire [31:0] instant_rpm_remainder;
wire [31:0] instant_rpm_result;
wire instant_rpm_rdy;
integer_division #(32) instant_rpm
                                        (   .clk(clk),
                                            .rst(rst),
                                            .start(~edge1),
                                            .dividend(32'h2FAF080),
                                            .divider({8'd0,pcnt0_out[23:0]}),
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
// Dwell angle calc end

//Буфер
wire [23:0] ignition_angle_0_buffer_out;
d_ff_wide #(24) ignition_angle_0_buffer
										(	.d(ignition_angle_0_out),
											.clk(clk),
											.rst(rst),
											.ena(~dwell_angle_rdy),
											.q(ignition_angle_0_buffer_out));
//Конец буфера

// Coil set point calc
wire [23:0] charge_angle_out;
integer_subtraction #(24) coil_set_point 
										(	.minuend(ignition_angle_0_buffer_out),
											.subtrahend(dwell_angle_result),
											.result(charge_angle_out));
// Coil set point calc end

//Буфер
wire [23:0] charge_angle_buffer_out;
d_ff_wide #(24) charge_angle_buffer
										(	.d(charge_angle_out),
											.clk(clk),
											.rst(rst),
											.ena(edge0 & dwell_angle_rdy),
											.q(charge_angle_buffer_out));

wire [23:0] ignition_angle_buffer_out;
d_ff_wide #(24) ignition_angle_buffer
										(	.d(ignition_angle_0_buffer_out),
											.clk(clk),
											.rst(rst),
											.ena(edge0 & dwell_angle_rdy),
											.q(ignition_angle_buffer_out));
//конец буфера

//компараторы
compare #(24) coil14_update_comp
										(	.dataa(acnt3_out),
											.datab(charge_angle_buffer_out),
											.alb(coil14_update_out));
											
wire coil14_update = edge0 & coil14_update_out;									
wire [23:0] coil14_charge_out;
d_ff_wide #(24) coil14_charge_buffer
										(	.d(charge_angle_buffer_out),
											.clk(clk),
											.rst(rst),
											.ena(coil14_update),
											.q(coil14_charge_out));
											
wire [23:0] coil14_ignition_out;
d_ff_wide #(24) coil14_ignition_buffer
										(	.d(ignition_angle_buffer_out),
											.clk(clk),
											.rst(rst),
											.ena(coil14_update),
											.q(coil14_ignition_out));
											
compare #(24) coil14_set_comp
										(	.dataa(acnt3_out),
											.datab(coil14_charge_out),
											.aeb(coil14_set_out));
											
compare #(24) coil14_reset_comp
										(	.dataa(acnt3_out),
											.datab(coil14_ignition_out),
											.aeb(coil14_reset_out));

wire coil14_trigger_rst = rst | ~hwag_start | coil14_reset_out;
d_ff_wide #(1) coil14_trigger (	.d(1'b1),
											.clk(clk),
											.rst(coil14_trigger_rst),
											.ena(coil14_set_out),
											.q(coil14_out));
//компараторы

endmodule
//`endif

