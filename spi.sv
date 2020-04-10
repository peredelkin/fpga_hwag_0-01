`ifndef SPI_SV
`define SPI_SV

module spi_slave (din,dout,ss,clk,rst,ena,data_in,data_out,req);

input wire din;
output wire dout;
input wire ss;
input wire clk;
input wire rst;
input wire ena;
input wire [7:0] data_in;

wire [7:0] buffer_in;

wire [7:0] buffer_out;
//assign dout = buffer_out[7];

output wire[7:0] data_out;
assign data_out = {buffer_out[6:0],din};

output wire req;

latch #(1) dout_latch
                                    (   .d(buffer_out[7]),
                                        .l(clk),
                                        .q(dout));
                                        
counter_compare #(3) data_counter
                                    (   .clk(~clk),
                                        .ena(ena),
                                        .rst(rst | ss),
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
                                        .rst(rst | ss),
                                        .ena(ena),
                                        .q(buffer_out));

endmodule

`endif
