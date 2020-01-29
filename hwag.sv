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

module hwag(clk,rst,ssram_we,ssram_re,ssram_addr,ssram_data,vr_in,vr_out,vr_edge_0,vr_edge_1);
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

wire [15:0] vr_filter_value = ssram_out [0];
// ssram_out[0]:[15:0 значение фильтра захвата]

wire [15:0] hwacr0 = ssram_out [1];
// ssram_out[1]:[15:2][1 выбор пары фронтов][0 включение захвата]

// hwag registers end

// vr input
input wire vr_in;
output wire vr_out,vr_edge_0,vr_edge_1;
capture_flt_edge_det_sel #(16) vr_filter (	.d(vr_in),
															.clk(clk),
															.rst(rst),
															.ena(hwacr0[0]), /*.ena(~hwag_start || cap_run_ena)*/
															.sel(hwacr0[1]),
															.flt_val(vr_filter_value),
															.filtered(vr_out),
															.edge0(vr_edge_0),
															.edge1(vr_edge_1));

// vr input end

endmodule

//`endif

