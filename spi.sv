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

simple_multiplexer #(1) spi_clk_polarity_sel
										(	.dataa(spi_clk),
											.datab(~spi_clk),
											.sel(spi_clk_polarity),
											.out(spi_clk_selected_polarity));

and(spi_clk_rise,spi_clk0,~spi_clk1);
and(spi_clk_fall,~spi_clk0,spi_clk1);
d_ff_wide #(2) spi_clk_cap
										(	.d({spi_clk0,spi_clk_selected_polarity}),
											.clk(clk),
											.rst(rst),
											.ena(ena & ~spi_ss),
											.q({spi_clk1,spi_clk0}));

simple_multiplexer #(2) spi_clk_phase_sel
										(	.dataa({spi_clk_fall,spi_clk_rise}),
											.datab({spi_clk_rise,spi_clk_fall}),
											.sel(spi_clk_phase),
											.out({spi_rx,spi_tx}));
											
endmodule

`endif
