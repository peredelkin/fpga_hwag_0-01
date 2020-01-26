
`ifndef DECODER_SV
`define DECODER_SV

module decoder_4_16 (in,out);
input wire [3:0] in;
output reg [15:0] out;
always @(*) begin
	case(in)
		4'h0 : out = 16'h0001;
      4'h1 : out = 16'h0002;
      4'h2 : out = 16'h0004;
      4'h3 : out = 16'h0008;
      4'h4 : out = 16'h0010;
      4'h5 : out = 16'h0020;
      4'h6 : out = 16'h0040;
      4'h7 : out = 16'h0080;
      4'h8 : out = 16'h0100;
      4'h9 : out = 16'h0200;
      4'hA : out = 16'h0400;
      4'hB : out = 16'h0800;
      4'hC : out = 16'h1000;
      4'hD : out = 16'h2000;
      4'hE : out = 16'h4000;
      4'hF : out = 16'h8000;
	endcase
end
endmodule

module decoder_8_row_column (in,row,column);
input wire [7:0] in;
output wire [15:0] row;
output wire [15:0] column;

decoder_4_16 row_decoder 		(.in(in[7:4]),.out(row));
decoder_4_16 column_decoder	(.in(in[3:0]),.out(column));
endmodule

`endif
