`ifndef SPI_SV
`define SPI_SV

module spi_slave (din,dout,clkin,ss,clk,rst,ena,data_in,data_out,req_r,req_f);

input wire din;
input wire clkin;
input wire ss;
input wire clk;
input wire rst;
input wire ena;
input wire [7:0] data_in;

wire [7:0] buffer_in;
wire [7:0] buffer_out;
output wire dout;
//assign dout = buffer_out[7];
output wire[7:0] data_out;
assign data_out = {buffer_out[6:0],din};

output wire req_r,req_f;

wire [1:0] clkin_cap_out;
and(rise,clkin_cap_out[0],~clkin_cap_out[1]);
and(fall,~clkin_cap_out[0],clkin_cap_out[1]);
and(req_r,req,rise);
and(req_f,req,fall);

d_ff_wide #(1) dout_shift
                                    (   .d(buffer_out[7]),
                                        .clk(~clkin),
                                        .rst(rst),
                                        .ena(ena),
                                        .q(dout));

d_ff_wide #(2) clkin_cap
                                    (   .d({clkin_cap_out[0],clkin}),
                                        .clk(clk),
                                        .rst(rst),
                                        .ena(ena),
                                        .q(clkin_cap_out));

counter_compare #(3) data_counter
                                    (   .clk(clk),
                                        .ena(rise),
                                        .rst(rst),
                                        .dtop(3'd7),
                                        .out_e_top(req));
                                        
simple_multiplexer #(8) shift_load_sw
                                    (   .dataa({buffer_out[6:0],din}),
                                        .datab(data_in),
                                        .sel(req),
                                        .out(buffer_in));

d_ff_wide #(8) data_buffer
                                    (   .d(buffer_in),
                                        .clk(clk),
                                        .rst(rst),
                                        .ena(rise),
                                        .q(buffer_out));

endmodule

`endif
