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

module hwag(clk,rst,ssram_we,ssram_re,ssram_addr,ssram_data,vr_in,vr_out);
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

wire [15:0] HWAGCSCR0;
ssram_bsrr #(16) hwacr0_bsrr (.bsrr(ssram_data),
										.clk(clk),
										.rst(rst),
										.bsr_ena(ssram_row[4] & ssram_column[0]),
										.brr_ena(ssram_row[4] & ssram_column[1]),
										.we(ssram_we & !ssram_re),
										.re(ssram_re & !ssram_we),
										.bsr_q(HWAGCSCR0));
// HWAGCSR0 [15:3][2 включение фильтра][1 задний фронт][0 включение захвата]
// HWAGCRR0 [15:3][2 выключение фильтра][1 передний фронт][0 выключение захвата]

// hwag registers end

// vr input
input wire vr_in;
output wire vr_out;
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

endmodule

//`endif

