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

module hwag(clk,rst,ssram_we,ssram_re,ssram_addr,ssram_data,vr_in,vr_out,hwagif);
input wire clk,rst;

// ssram interface
input wire ssram_we,ssram_re;
input wire [7:0] ssram_addr;
inout wire [15:0] ssram_data;
wire [15:0] ssram_row;
wire [15:0] ssram_column;
wire [15:0] ssram_out [63:0];

decoder_8_row_column ssram_decoder (.in(ssram_addr),.row(ssram_row),.column(ssram_column));

// ssram
ssram_256 #(16,64) ssram (	.clk(clk),
									.rst(rst),
									.we(ssram_we & !ssram_re),
									.re(ssram_re & !ssram_we),
									.row(ssram_row),
									.column(ssram_column),
									.data(ssram_data),
									.out(ssram_out));
// ssram end
// ssram interface end

// hwag registers

wire [15:0] HWASFCR = ssram_out [0];
// HWASFCR [15:0 значение фильтра захвата]


// Hwag Global Control Set/Clear Register
wire [15:0] HWAGCSCR0;
ssram_bsrr #(16) HWAGCSCR0_bsrr (.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.bsr_ena(ssram_row[4] & ssram_column[0]),
										.brr_ena(ssram_row[4] & ssram_column[1]),
										.we(ssram_we & !ssram_re),
										.re(ssram_re & !ssram_we),
										.bsr_q(HWAGCSCR0));

// Hwag Interrupt Enable Set/Clear Register
wire [15:0] HWAIESCR;
ssram_bsrr #(16) HWAIER_bsrr (.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.bsr_ena(ssram_row[4] & ssram_column[2]),
										.brr_ena(ssram_row[4] & ssram_column[3]),
										.we(ssram_we & !ssram_re),
										.re(ssram_re & !ssram_we),
										.bsr_q(HWAIESCR));
// Hwag Interrupt Flag Register
wire [15:0] HWAIFR;
wire [15:0] HWAIF;
assign HWAIF[0] = vr_edge_0;
assign HWAIF[1] = pcnt_ovf;
ssram_ifr #(16) HWAIFR_ifr (	.flag(HWAIF & HWAIESCR),
										.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.frr_ena(ssram_row[4] & ssram_column[4]),
										.we(ssram_we & !ssram_re),
										.re(ssram_re & !ssram_we),
										.fsr_q(HWAIFR));
output wire hwagif;
assign hwagif = 	HWAIFR[15] | HWAIFR[14] | HWAIFR[13] | HWAIFR[12] |
						HWAIFR[11] | HWAIFR[10] | HWAIFR[9]  | HWAIFR[8]  |
						HWAIFR[7]  | HWAIFR[6]  | HWAIFR[5]  | HWAIFR[4]  |
						HWAIFR[3]  | HWAIFR[2]  | HWAIFR[1]  | HWAIFR[0];
// hwag registers end

// Variable Reluctance Sensor input
input wire vr_in;
output wire vr_out;
wire vr_edge_0,vr_edge_1;
capture_flt_edge_det_sel #(16) vr_filter (	.d(vr_in),
															.clk(clk),
															.rst(rst),
															.filt_ena(HWAGCSCR0[2]),
															.out_ena(HWAGCSCR0[0]), /*.ena(~hwag_start || cap_run_ena)*/
															.sel(HWAGCSCR0[1]),
															.flt_val(HWASFCR),
															.filtered(vr_out),
															.edge0(vr_edge_0),
															.edge1(vr_edge_1));

// Variable Reluctance Sensor input end

// Period counter
wire pcnt_e_top;
wire pcnt_ovf;
wire pcnt_rst;
wire [23:0] pcnt_out;
d_ff_wide #(1) pcnt_ovf_ff (	.d(pcnt_e_top),
										.clk(clk),
										.rst(rst),
										.ena(HWAGCSCR0[0]),
										.q(pcnt_ovf));
										
d_ff_wide #(1) pcnt_rst_ff (	.d(vr_edge_1),
										.clk(clk),
										.rst(rst),
										.ena(HWAGCSCR0[0]),
										.q(pcnt_rst));

counter_compare #(24) pcnt (	.clk(clk),
										.ena(HWAGCSCR0[0] & ~HWAIFR[1]),
										.rst(rst | pcnt_ovf | pcnt_rst),
										.dout(pcnt_out),
										.dtop(24'hFFFFFF),
										.out_e_top(pcnt_e_top));
// Period counter end

// Last three periods
wire [23:0] pcap0,pcap1,pcap2;
period_capture_3 #(24) pcap (	.d(pcnt_out),
										.clk(clk),
										.rst(rst | HWAIFR[1]),
										.ena(HWAGCSCR0[0] & vr_edge_0),
										.q0(pcap0),
										.q1(pcap1),
										.q2(pcap2));

buffer_z #(16) pcap0_read_l (	.ena(ssram_row[4] & ssram_column[5]),
										.d(pcap0[15:0]),
										.q(ssram_data));
buffer_z #(16) pcap0_read_h (	.ena(ssram_row[4] & ssram_column[6]),
										.d({8'b0,pcap0[23:16]}),
										.q(ssram_data));
// Last three periods end

endmodule

//`endif

