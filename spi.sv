`ifndef SPI_SV
`define SPI_SV

module spi_slave (spi_in,spi_out,spi_clk,spi_ss,clk,rst,ena,bus_in,bus_out,tx,rx);

input wire spi_in;
output wire spi_out;
input wire spi_clk;
input wire spi_ss;
input wire clk;
input wire rst;
input wire ena;
input wire [7:0] bus_in;
output wire [7:0] bus_out;
output wire tx;
output wire rx;

and(spi_clk_rise,spi_clk0,~spi_clk1);
and(spi_clk_fall,~spi_clk0,spi_clk1);

wire spi_rx = spi_clk_fall;
wire spi_tx = spi_clk_rise;

assign bus_out[0] = spi_in;

wire [7:0] tx_shift_buffer_out;
assign spi_out = tx_shift_buffer_out[7];
wire [7:0] tx_shift_load_out;

d_ff_wide #(1) ff_spi_clk0
										(	.d(spi_clk),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena),
											.q(spi_clk0));
											
d_ff_wide #(1) ff_spi_clk1
										(	.d(spi_clk0),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena),
											.q(spi_clk1));

//RX
counter_compare #(3) rx_counter
										(	.clk(clk),
											.ena(ena & spi_rx),
											.rst(rst | spi_ss),
											.dtop(3'd7),
											.out_e_top(rx_req));

d_ff_wide #(7) rx_shift_buffer
										(	.d(bus_out[6:0]),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(spi_rx),
											.q(bus_out[7:1]));
											
and(rx,rx_req,spi_rx);

//CRC RX
wire [7:0] crc_rx_out;
crc8b spi_crc_rx 					(	.serial_in(spi_in),
											.clk(clk),
											.ena(ena & spi_rx),
											.rst(rst | spi_ss),
											.crc_conf(8'b00000111),
											.crc_out(crc_rx_out));
wire [7:0] crc_rx_buffer_out;
d_ff_wide #(8) crc_rx_buffer	(	.d(crc_rx_out),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena & tx),
											.q(crc_rx_buffer_out));
//CRC RX end
											
//TX
counter_compare #(3) tx_counter
										(	.clk(clk),
											.ena(ena & spi_tx),
											.rst(rst | spi_ss),
											.dtop(3'd0),
											.out_e_top(tx_req));

simple_multiplexer #(8) tx_shift_load_sel
										(	.dataa({tx_shift_buffer_out[6:0],1'b0}),
											.datab(bus_in),
											.sel(tx_req),
											.out(tx_shift_load_out));

d_ff_wide #(8) tx_shift_buffer
										(	.d(tx_shift_load_out),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(spi_tx),
											.q(tx_shift_buffer_out));

and(tx,tx_req,spi_tx);

endmodule

`endif
