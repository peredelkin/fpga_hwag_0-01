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

module hwag(clk,cap_in,cap_out,gap_out);
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

wire [23:0] pcnt_out;											
counter_compare #(24) pcnt 	(	.clk(clk),
											.ena(pcnt_ne_top),
											.rst(rst),
											.srst(edge1),
											.sload(1'b0),
											.dload(23'd0),
											.dout(pcnt_out),
											.dtop(24'hFFFFFF),
											.out_e_top(pcnt_e_top),
											.out_ne_top(pcnt_ne_top));

wire [23:0] pcnt0_out,pcnt1_out,pcnt2_out;
period_capture_3 #(24) pcnt_cap (.d(pcnt_out),
											.clk(clk),
											.rst(rst | pcnt_e_top),
											.ena(edge0),
											.q0(pcnt0_out),
											.q1(pcnt1_out),
											.q2(pcnt2_out));

output wire gap_out;
gap_search #(24) gap_start_srch (.cap0(pcnt0_out),
											.cap1(pcnt1_out),
											.cap2(pcnt2_out),
											.gap(gap_out));

endmodule
//`endif

