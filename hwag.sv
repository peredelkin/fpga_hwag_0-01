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

module hwag(clk,rst,ssram_we,ssram_re,ssram_addr,ssram_data,vr_in);
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

//vr input
input wire vr_in;
wire [16:0] vr_filter_value = ssram_out [0];
// addr 0: [15 enable input][14 edge select][13:0 filter value]
capture_flt_edge_det_sel #(14) vr_filter (	.d(vr_in),
															.clk(clk),
															.rst(rst),
															.ena(vr_filter_value[15]), /*.ena(~hwag_start || cap_run_ena)*/
															.sel(vr_filter_value[14]),
															.flt_val(vr_filter_value[13:0]),
															.filtered(vr_filtered),
															.edge0(vr_edge_0),
															.edge1(vr_edge_1));

//vr

endmodule

//`endif

