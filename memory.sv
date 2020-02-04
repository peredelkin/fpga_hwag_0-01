
`ifndef MEMORY_SV
`define MEMORY_SV

//bit set/reset register
module ssram_bsrr #(parameter WIDTH=1) (data,clk,rst,bsr_ena,brr_ena,we,re,bsr_q);
inout wire [WIDTH-1:0] data;
input wire clk,rst,bsr_ena,brr_ena,we,re;
output wire [WIDTH-1:0] bsr_q;
wire [WIDTH-1:0] brr_q;

genvar i;
generate
	for (i=0; i<=WIDTH-1; i=i+1) begin : gen_bsrr_block
	d_ff_wide #(1) bsr_bit (.d(data[i]),
									.clk(clk),
									.rst(rst | brr_q[i]),
									.ena(bsr_ena & we),
									.q(bsr_q[i]));

	d_ff_wide #(1) brr_bit (.d(data[i]),
									.clk(clk),
									.rst(rst | ~bsr_q[i]),
									.ena(brr_ena & we),
									.q(brr_q[i]));
end
endgenerate

	buffer_z #(WIDTH) bsr_buffer (	.ena(bsr_ena & re),
												.d(bsr_q),
												.q(data));
												
	buffer_z #(WIDTH) brr_buffer (	.ena(brr_ena & re),
												.d(bsr_q),
												.q(data));
endmodule

//interrupt flag register
module ssram_ifr #(parameter WIDTH=1) (flag,data,clk,rst,frr_ena,we,re,fsr_q);
input wire [WIDTH-1:0] flag;
inout wire [WIDTH-1:0] data;
input wire clk,rst,frr_ena,we,re;
output wire [WIDTH-1:0] fsr_q;
wire [WIDTH-1:0] frr_q;

genvar i;
generate
	for (i=0; i<=WIDTH-1; i=i+1) begin : gen_bsrr_block
	d_ff_wide #(1) fsr_bit (.d(flag[i] | fsr_q[i]),
									.clk(clk),
									.rst(rst | frr_q[i]),
									.ena(1'b1),/*(!)*/
									.q(fsr_q[i]));

	d_ff_wide #(1) frr_bit (.d(data[i]),
									.clk(clk),
									.rst(rst | ~fsr_q[i]),
									.ena(frr_ena & we),
									.q(frr_q[i]));
end
endgenerate
												
	buffer_z #(WIDTH) brr_buffer (	.ena(frr_ena & re),
												.d(fsr_q),
												.q(data));
endmodule

module ssram_register #(parameter WIDTH=1) (d,clk,rst,ena,we,re,q);
inout wire [WIDTH-1:0] d;
input wire clk,rst,ena,we,re;
output wire[WIDTH-1:0] q;

wire ena_delay = 1'b1;
//d_ff_wide #(1) ena_delay_ff(.d(ena),.clk(clk),.rst(rst),.ena(1'b1),.q(ena_delay));

d_ff_wide #(WIDTH) ssram_ff (.d(d),.clk(clk),.rst(rst),.ena(ena_delay & ena & we),.q(q));
buffer_z #(WIDTH) ssram_buffer (.ena(ena_delay & ena & re),.d(q),.q(d));
endmodule

module ssram_256 #(parameter WIDTH=1,DEPTH=1) (clk,rst,we,re,row,column,data,out);
input wire clk,rst,we,re;
input wire [15:0] row;
input wire [15:0] column;
inout wire [WIDTH-1:0] data;
output wire [WIDTH-1:0] out [DEPTH-1:0];

genvar i;
generate
	for (i=0; i<=DEPTH-1; i=i+1) begin : gen_ssram_block
	ssram_register #(WIDTH) ssram_block (	.d(data),
														.clk(clk),
														.rst(rst),
														.ena(row[i/16] & column[i%16]),
														.we(we),
														.re(re),
														.q(out[i]));
end
endgenerate
endmodule

/* M9K example
module ram9k (clk,we,addr,w_data,r_data);
input wire clk,we;
input wire [7:0] addr;
input wire [15:0] w_data;
output reg [15:0] r_data;

(* ramstyle = "M9K" *) reg [15:0] ram [255:0];

always @(posedge clk) begin
	if(we) ram [addr] <= w_data;
	r_data <= ram [addr];
end

endmodule
*/

`endif
