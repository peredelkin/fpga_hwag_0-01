
`ifndef CAPTURE_SV
`define CAPTURE_SV

module pin_cnt_filter #(parameter WIDTH=1)
                        (d,clk,rst,ena,flt_val,q);
input wire d,clk,rst,ena;
input wire [WIDTH-1:0] flt_val;
output wire q;
xor(dqxor,d,q); //d not equal q
and(q_ena,ena,cnt_ge_flt); // enable q if aeb and ena
counter_compare #(WIDTH) cnt_comp(  .clk(clk),
                                    .ena(cnt_l_flt),
                                    .rst(rst),
                                    .srst(~dqxor),
                                    .dtop(flt_val),
                                    .out_l_top(cnt_l_flt),
                                    .out_ge_top(cnt_ge_flt));
                                    
d_ff_wide #(1) d_ff(.d(d),.clk(clk),.rst(rst),.ena(q_ena),.q(q));
endmodule

module pin_edge_gen(d,clk,rst,ena,rise0,rise1,fall0,fall1);
input wire d,clk,rst,ena;
output wire rise0,rise1,fall0,fall1;
wire q0,q1;
and(rise0,d,~q0);
and(rise1,q0,~q1);
and(fall0,~d,q0);
and(fall1,~q0,q1);
d_ff_wide #(1) d_ff0(.d(d),.clk(clk),.rst(rst),.ena(ena),.q(q0));
d_ff_wide #(1) d_ff1(.d(q0),.clk(clk),.rst(rst),.ena(ena),.q(q1));
endmodule

module capture_flt_edge_det_sel #(parameter WIDTH=1)
                  (d,clk,rst,ena,sel,flt_val,filtered,edge0,edge1);
input wire d,clk,rst,ena,sel;
input wire [WIDTH-1:0] flt_val;
output wire filtered,edge0,edge1;
pin_cnt_filter #(WIDTH) pin_filter (.d(d),.clk(clk),.rst(rst),.ena(ena),.flt_val(flt_val),.q(filtered));
pin_edge_gen pin_edge (.d(filtered),.clk(clk),.rst(rst),.ena(ena),.rise0(rise0),.rise1(rise1),.fall0(fall0),.fall1(fall1));
simple_multiplexer #(2) mult(.dataa({rise0,rise1}),.datab({fall0,fall1}),.sel(sel),.out({edge0,edge1}));
endmodule

`endif
