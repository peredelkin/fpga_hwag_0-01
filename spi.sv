`ifndef SPI_SV
`define SPI_SV

module spi_base (din,clk,rst,b_ena,c_ena,shift_load,req,bus_in,bus_out);

input wire din;
input wire clk;
input wire rst;
input wire ena;
input wire shift_load;
output wire req;

input wire shift_load;

input wire [7:0] bus_in;
output wire [7:0] bus_out;

wire [7:0] buffer_in;

simple_multiplexer #(8) shift_load_sw 
									(	.dataa({bus_out[6:0],din}) ,
										.datab(bus_in),
										.sel(shift_load),
										.out(buffer_in));

d_ff_wide #(8) spi_buffer
									(	.d(buffer_in),
										.clk(clk),
										.rst(rst),
										.ena(b_ena),
										.q(bus_out));

counter_compare #(3) data_count
									(	.clk(clk),
										.ena(c_ena),
										.rst(rst),
										.dtop(3'd7),
										.out_e_top(req));
endmodule

`endif