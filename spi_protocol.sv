`ifndef SPI_PROTOCOL_SV
`define SPI_PROTOCOL_SV

module hwag_spi_rx_data_frame 
			(clk,rst,spi_ss,spi_rx,spi_bus_out,spi_crc_rx_out,spi_hwag_cmd,spi_hwag_addr,spi_hwag_data,spi_crc_rx_equal,spi_ss_rise);
input wire clk,rst,spi_ss,spi_rx;
input wire [7:0] spi_bus_out;
input wire [7:0] spi_crc_rx_out;
output wire spi_crc_rx_equal;
output wire spi_ss_rise;

wire [7:0] spi_bus_rx_buffer_out [6:0];
wire [7:0] spi_crc_rx_out_buffer_out;

wire [2:0] spi_rx_data_counter_out;
counter #(3) spi_rx_data_counter (.clk(clk),.rst(rst | spi_ss),.ena(spi_rx),.data_out(spi_rx_data_counter_out));

wire [7:0] spi_rx_data_select;
decoder_3_8 spi_rx_data_decoder (.in(spi_rx_data_counter_out),.out(spi_rx_data_select));

//Spi data frame
// [CMD8]:[ADDR8]:[DATA32]:[CRC8]
output wire [7:0] spi_hwag_cmd = spi_bus_rx_buffer_out[0];
output wire [7:0] spi_hwag_addr = spi_bus_rx_buffer_out[1];
output wire [31:0] spi_hwag_data = {spi_bus_rx_buffer_out[5],spi_bus_rx_buffer_out[4],spi_bus_rx_buffer_out[3],spi_bus_rx_buffer_out[2]};
wire [7:0] spi_hwag_crc = spi_bus_rx_buffer_out[6];
//Spi data frame end

d_ff_wide #(8) spi_bus_rx_buffer_0
										(	.d(spi_bus_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[0]),
											.q(spi_bus_rx_buffer_out[0]));
											
d_ff_wide #(8) spi_bus_rx_buffer_1
										(	.d(spi_bus_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[1]),
											.q(spi_bus_rx_buffer_out[1]));
											
d_ff_wide #(8) spi_bus_rx_buffer_2
										(	.d(spi_bus_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[2]),
											.q(spi_bus_rx_buffer_out[2]));
											
d_ff_wide #(8) spi_bus_rx_buffer_3
										(	.d(spi_bus_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[3]),
											.q(spi_bus_rx_buffer_out[3]));
										
d_ff_wide #(8) spi_bus_rx_buffer_4
										(	.d(spi_bus_out),
											.clk(clk),.rst(rst),
											.ena(spi_rx & spi_rx_data_select[4]),
											.q(spi_bus_rx_buffer_out[4]));
											
d_ff_wide #(8) spi_bus_rx_buffer_5
										(	.d(spi_bus_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[5]),
											.q(spi_bus_rx_buffer_out[5]));
										
d_ff_wide #(8) spi_bus_rx_buffer_6
										(	.d(spi_bus_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[6]),
											.q(spi_bus_rx_buffer_out[6]));

d_ff_wide #(8) spi_crc_rx_out_buffer 
										(	.d(spi_crc_rx_out),
											.clk(clk),
											.rst(rst),
											.ena(spi_rx & spi_rx_data_select[6]),
											.q(spi_crc_rx_out_buffer_out));
											
compare #(8) spi_crc_rx_comp	(	.dataa(spi_hwag_crc),
											.datab(spi_crc_rx_out_buffer_out),
											.aeb(spi_crc_rx_equal));

d_ff_wide #(1) spi_ss_cap		(	.d(spi_ss),
											.clk(clk),
											.rst(rst),
											.ena(1'b1),
											.q(spi_ss0));
assign spi_ss_rise = spi_ss & ~spi_ss0;
endmodule

`endif