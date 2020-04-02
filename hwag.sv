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

module hwag(clk,cap_in,cap_out);
input wire clk;
input wire cap_in;
output wire cap_out;

wire edge0,edge1;

capture_flt_edge_det_sel #(4,10) vr_filter 
										(	.d(cap_in),
											.clk(clk),
											.rst(rst),
											.fst_ena(1'b1),
											.snd_ena(1'b1),
											.out_ena(1'b1),
											.fst_val(4'd7),
											.snd_val(10'd127),
											.filtered(cap_out),
											.sel(1'b1),
											.edge0(edge0),
											.edge1(edge1));

endmodule

//`endif

