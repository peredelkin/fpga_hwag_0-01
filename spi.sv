`ifndef SPI_SV
`define SPI_SV

module spi_slave (spi_in,spi_out,spi_clk,spi_ss,clk,rst,ena,bus_in,bus_out,crc_rx_out,tx,rx);

input wire spi_in;
output wire spi_out;
input wire spi_clk;
input wire spi_ss;
input wire clk;
input wire rst;
input wire ena;
input wire [7:0] bus_in;
output wire [7:0] bus_out;
output wire [7:0] crc_rx_out;
output wire tx;
output wire rx;

and(spi_clk_rise,spi_clk0,~spi_clk1);
and(spi_clk_fall,~spi_clk0,spi_clk1);

wire spi_rx = spi_clk_fall;
wire spi_tx = spi_clk_rise;

wire [7:0] tx_shift_buffer_out;
assign spi_out = tx_shift_buffer_out[7];
wire [7:0] tx_shift_load_out;

d_ff_wide #(2) ff_spi_clk0
										(	.d({spi_clk0,spi_clk}),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena & ~spi_ss),
											.q({spi_clk1,spi_clk0}));
//RX
counter_compare #(3) rx_counter
										(	.clk(clk),
											.ena(ena & spi_rx),
											.rst(rst | spi_ss),
											.dtop(3'd7),
											.out_e_top(rx_req));

d_ff_wide #(8) rx_shift_buffer
										(	.d({bus_out[6:0],spi_in}),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(spi_rx),
											.q(bus_out[7:0]));
											
//and(rx,rx_req,spi_rx);
d_ff_wide #(1) rx_req_delay	(	.d(rx_req & spi_rx),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena),
											.q(rx));

//CRC RX
crc8b spi_crc_rx 					(	.serial_in(bus_out[7]),
											.clk(clk),
											.ena(ena & spi_rx),
											.rst(rst | spi_ss),
											.crc_conf(8'd7),
											.crc_out(crc_rx_out));
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
