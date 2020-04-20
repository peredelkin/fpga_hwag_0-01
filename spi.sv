`ifndef SPI_SV
`define SPI_SV

module spi_slave (spi_in,spi_out,spi_clk,spi_ss,spi_clk_polarity,spi_clk_phase,clk,rst,ena,bus_in,bus_out);

input wire spi_in;
output wire spi_out;
input wire spi_clk;
input wire spi_ss;
input wire spi_clk_polarity;
input wire spi_clk_phase;
input wire clk;
input wire rst;
input wire ena;
input wire [7:0] bus_in;
output wire [7:0] bus_out;

/*simple_multiplexer #(1) spi_clk_polarity_sel
										(	.dataa(spi_clk),
											.datab(~spi_clk),
											.sel(spi_clk_polarity),
											.out(spi_clk_selected_polarity));*/

and(spi_clk_rise,spi_clk0,~spi_clk1);
and(spi_clk_fall,~spi_clk0,spi_clk1);
d_ff_wide #(2) spi_clk_cap
										(	.d({spi_clk0,spi_clk}),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena),
											.q({spi_clk1,spi_clk0}));

/*simple_multiplexer #(2) spi_clk_phase_sel
										(	.dataa({spi_clk_fall,spi_clk_rise}),
											.datab({spi_clk_rise,spi_clk_fall}),
											.sel(spi_clk_phase),
											.out({spi_rx,spi_tx}));*/
wire spi_rx = spi_clk_fall;
wire spi_tx = spi_clk_rise;

counter_compare #(3) rx_counter
										(	.clk(clk),
											.ena(ena & spi_rx),
											.rst(rst | spi_ss),
											.dtop(3'd7),
											.out_e_top(rx_top));

and(rx_req,rx_top,~rx_top0);
d_ff_wide #(1) ff_rx_top
										(	.d(rx_top),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(ena),
											.q(rx_top0));

counter_compare #(3) tx_counter
										(	.clk(clk),
											.ena(ena & spi_tx),
											.rst(rst | spi_ss),
											.dtop(3'd0),
											.out_e_top(tx_top));

wire [7:0] tx_shift_buffer_out;
assign spi_out = tx_shift_buffer_out[7];
wire [7:0] tx_shift_load_out;

simple_multiplexer #(8) tx_shift_load_sel
										(	.dataa({tx_shift_buffer_out[6:0],1'b0}),
											.datab(bus_in),
											.sel(tx_top),
											.out(tx_shift_load_out));

d_ff_wide #(8) tx_shift_buffer
										(	.d(tx_shift_load_out),
											.clk(clk),
											.rst(rst | spi_ss),
											.ena(spi_tx),
											.q(tx_shift_buffer_out));


endmodule

`endif
