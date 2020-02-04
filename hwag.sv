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
ssram_ifr #(16) HWAIFR_ifr (	.flag(HWAIF & HWAIESCR),
										.data(ssram_data),
										.clk(clk),
										.rst(rst),
										.frr_ena(ssram_row[4] & ssram_column[4]),
										.we(ssram_we & !ssram_re),
										.re(ssram_re & !ssram_we),
										.fsr_q(HWAIFR));
output wire hwagif;
or(hwagif,HWAIFR);
// hwag registers end

// vr input
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

// vr input end

// pcnt enable
//wire pcnt_ena;
//srs_ff srs_ff_pcnt_enable(.clk(clk),.rst(rst),.sset(),.srst(),.q(pcnt_ena));
// pcnt enable end

endmodule

//`endif

