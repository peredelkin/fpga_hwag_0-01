
module ram9k_block #(parameter WIDTH=1) (d,clk,we,q);
input wire clk,we;
input wire [WIDTH-1:0] d;
output wire [WIDTH-1:0] q;
(* ramstyle = "M9K" *) reg [WIDTH-1:0] ram;
assign q = ram;

always @(posedge clk) begin
	if(we) ram <= d;
end

endmodule

module hwag(clk,rst,ssram_we,ssram_re,ssram_addr,ssram_data);
input wire clk,rst;

// ssram interface
input wire ssram_we,ssram_re;
input wire [7:0] ssram_addr;
inout wire [15:0] ssram_data;
wire [15:0] ssram_row;
wire [15:0] ssram_column;
wire [15:0] ssram_out [255:0];

decoder_8_row_column ssram_decoder (.in(ssram_addr),.row(ssram_row),.column(ssram_column));

// ssram
ssram_256 #(16,64) ssram (	.clk(clk),
							.rst(rst),
							.we(ssram_we),
							.re(ssram_re),
							.row(ssram_row),
							.column(ssram_column),
							.data(ssram_data),
							.out(ssram_out[63:0]));
// ssram end
// ssram interface end

endmodule
