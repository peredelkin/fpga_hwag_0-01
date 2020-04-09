`ifndef SPI_SV
`define SPI_SV

module spi_slave (din,dout,clkin,ss,clk,rst,ena,data_in,data_out,req_r,req_w);

input wire din;
output wire dout;
input wire clkin;
input wire ss;
input wire clk;
input wire rst;
input wire ena;
input wire [7:0] data_in;
output wire[7:0] data_out;
output wire req_r,req_w;

wire [1:0] clkin_cap_out;
and(rise,clkin_cap_out[0],~clkin_cap_out[1]);
and(fall,~clkin_cap_out[0],clkin_cap_out[1]);
and(req_r,req,rise);
and(req_w,req,fall);
d_ff_wide #(2) clkin_cap
                                    (   .d({clkin_cap_out[0],clkin}),
                                        .clk(clk),
                                        .rst(rst),
                                        .ena(ena),
                                        .q(clkin_cap_out));

counter_compare #(3) data_counter
                                    (   .clk(clk),
                                        .ena(fall),
                                        .rst(rst),
                                        .dtop(3'd7),
                                        .out_e_top(req));

d_ff_wide #(8) data_buffer
                                    (   .d({data_out[6:0],din}),
                                        .clk(clk),
                                        .rst(rst),
                                        .ena(rise),
                                        .q(data_out));

endmodule

`endif
