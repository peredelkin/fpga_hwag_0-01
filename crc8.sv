`ifndef CRC8_V
`define CRC8_V

module crc8b (serial_in,clk,ena,rst,crc_conf,crc_out);

input wire serial_in;
input wire clk;
input wire ena;
input wire rst;

input wire [7:0] crc_conf;

output wire [7:0] crc_out;

wire [7:0] sel_out;

xor(xor1,crc_out[0],xor0);
xor(xor2,crc_out[1],xor0);
xor(xor3,crc_out[2],xor0);
xor(xor4,crc_out[3],xor0);
xor(xor5,crc_out[4],xor0);
xor(xor6,crc_out[5],xor0);
xor(xor7,crc_out[6],xor0);
xor(xor0,crc_out[7],serial_in);

simple_multiplexer #(1) sel_bit0 (.dataa(serial_in),.datab(xor0),.sel(crc_conf[0]),.out(sel_out[0]));
simple_multiplexer #(1) sel_bit1 (.dataa(crc_out[0]),.datab(xor1),.sel(crc_conf[1]),.out(sel_out[1]));
simple_multiplexer #(1) sel_bit2 (.dataa(crc_out[1]),.datab(xor2),.sel(crc_conf[2]),.out(sel_out[2]));
simple_multiplexer #(1) sel_bit3 (.dataa(crc_out[2]),.datab(xor3),.sel(crc_conf[3]),.out(sel_out[3]));
simple_multiplexer #(1) sel_bit4 (.dataa(crc_out[3]),.datab(xor4),.sel(crc_conf[4]),.out(sel_out[4]));
simple_multiplexer #(1) sel_bit5 (.dataa(crc_out[4]),.datab(xor5),.sel(crc_conf[5]),.out(sel_out[5]));
simple_multiplexer #(1) sel_bit6 (.dataa(crc_out[5]),.datab(xor6),.sel(crc_conf[6]),.out(sel_out[6]));
simple_multiplexer #(1) sel_bit7 (.dataa(crc_out[6]),.datab(xor7),.sel(crc_conf[7]),.out(sel_out[7]));

d_ff_wide #(1) crc_bit0 (.d(sel_out[0]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[0]));
d_ff_wide #(1) crc_bit1 (.d(sel_out[1]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[1]));
d_ff_wide #(1) crc_bit2 (.d(sel_out[2]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[2]));
d_ff_wide #(1) crc_bit3 (.d(sel_out[3]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[3]));
d_ff_wide #(1) crc_bit4 (.d(sel_out[4]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[4]));
d_ff_wide #(1) crc_bit5 (.d(sel_out[5]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[5]));
d_ff_wide #(1) crc_bit6 (.d(sel_out[6]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[6]));
d_ff_wide #(1) crc_bit7 (.d(sel_out[7]),.clk(clk),.rst(rst),.ena(ena),.q(crc_out[7]));

endmodule

`endif