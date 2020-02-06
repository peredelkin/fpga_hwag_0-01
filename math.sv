`ifndef MATH_V
`define MATH_V

module integer_subtraction #(parameter WIDTH=1)
                            (minuend,subtrahend,result);
input wire [WIDTH-1:0] minuend,subtrahend;
output reg [WIDTH-1:0] result;
always @(*) begin
    result <= minuend - subtrahend;
end
endmodule

//модуль вычитания со сдигом для модуля двоичного деления
module integer_shift_subtraction #(parameter WIDTH=1)
                                    (d,clk,rst,ena,divider,remainder,q);
input wire d,clk,rst,ena;
output wire q;
input wire [WIDTH-1:0] divider;
output wire[WIDTH-1:0] remainder;
wire [WIDTH-1:0] difference;
wire [WIDTH-1:0] minuend = {remainder_q[WIDTH-2:0],d};
wire [WIDTH-2:0] remainder_q;
wire [WIDTH-2:0] remainder_d = remainder[WIDTH-2:0];
wire sub_q;
not(q,sub_q);

d_ff_wide #(WIDTH-1) d_remainder( .d(remainder_d),
                                .clk(clk),
                                .rst(rst),
                                .ena(ena),
                                .q(remainder_q));
                                                             
integer_subtraction #(WIDTH+1) sub( .minuend({1'b0,minuend}),
                                    .subtrahend({1'b0,divider}),
                                    .result({sub_q,difference}));
                                    
simple_multiplexer #(WIDTH) mult(   .dataa(difference),
                                    .datab(minuend),
                                    .sel(sub_q),
                                    .out(remainder));                                                             
endmodule

//модуль целочисленного деления
module integer_division #(parameter WIDTH=1)
                        (clk,rst,start,dividend,divider,remainder,result,rdy);

input wire clk,rst,start;
input wire [WIDTH-1:0] dividend,divider;
output wire[WIDTH-1:0] remainder;
output wire[WIDTH-1:0] result;
output wire rdy;
wire [WIDTH-1:0] dividend_q;
wire result_d;
assign result = {dividend_q[WIDTH-2:0],result_d};

localparam CNT_WIDTH = $clog2(WIDTH);
localparam [CNT_WIDTH-1:0] CNT_TOP = WIDTH - 1;

counter_compare #(CNT_WIDTH) step_count(.clk(clk),
                                    .ena(~rdy),
                                    .rst(rst || ~start),
                                    .dtop(CNT_TOP),
                                    .out_e_top(rdy));
                        
d_shift_left_load #(WIDTH) d_dividend(  .d(result_d),
                                        .clk(clk),
                                        .rst(rst),
                                        .sshift(~rdy),
                                        .sload(~start),
                                        .load_data(dividend),
                                        .q(dividend_q));
                                                
integer_shift_subtraction #(WIDTH) shift_sub(   .d(dividend_q[WIDTH-1]),
                                                .clk(clk),
                                                .rst(rst || ~start),
                                                .ena(~rdy),
                                                .divider(divider),
                                                .remainder(remainder),
                                                .q(result_d));

endmodule

module integer_addition #(parameter WIDTH=1)
                            (argumenta,argumentb,result);
input wire [WIDTH-1:0] argumenta,argumentb;
output reg [WIDTH-1:0] result;
always @(*) begin
    result <= argumenta + argumentb;
end
endmodule

//модуль целочисленного умножения
module integer_multiplication #(parameter WIDTH=1)
                                (clk,rst,start,multiplicand,multiplier,result,rdy);
                                
input wire clk,rst,start;
output wire rdy;

input wire [WIDTH-1:0] multiplicand,multiplier;
output wire [(WIDTH*2)-1:0] result;
                                
wire [WIDTH-1:0] multiplier_q;
wire [(WIDTH*2)-2:0] result_q;
wire [WIDTH-1:0] argumenta;

localparam CNT_WIDTH = $clog2(WIDTH);
localparam [CNT_WIDTH-1:0] CNT_TOP = WIDTH - 1;
localparam [WIDTH-1:0] ZERO = 0;

counter_compare #(CNT_WIDTH) step_count(.clk(clk),
                                        .ena(~rdy),
                                        .rst(rst || ~start),
                                        .dtop(CNT_TOP),
                                        .out_e_top(rdy));
                                
d_shift_left_load #(WIDTH) d_multiplier(.d(1'b0),
                                        .clk(clk),
                                        .rst(rst),
                                        .sshift(~rdy),
                                        .sload(~start),
                                        .load_data(multiplier),
                                        .q(multiplier_q));
                                        
d_ff_wide #((WIDTH*2)-1) d_result(      .d(result[(WIDTH*2)-2:0]),
                                        .clk(clk),
                                        .rst(rst || ~start),
                                        .ena(~rdy),
                                        .q(result_q));
                                
integer_addition #(WIDTH*2) add(        .argumenta({ZERO,argumenta}),
                                        .argumentb({result_q,1'b0}),
                                        .result(result));

simple_multiplexer #(WIDTH) mult(   .dataa(ZERO),
                                    .datab(multiplicand),
                                    .sel(multiplier_q[WIDTH-1]),
                                    .out(argumenta));
endmodule

//tckc top at gap calculation
module hwag_tckc_actual_top #(parameter WIDTH=1)
                        (gap_point,tckc_top,tckc_actial_top);
input wire gap_point;
input wire [WIDTH-1:0] tckc_top;
output wire[WIDTH-1:0] tckc_actial_top;
wire [WIDTH-1:0] tckc_gap_top;

integer_addition #(WIDTH) add(  .argumenta({tckc_top[WIDTH-2:0],1'b0}),
                                .argumentb(tckc_top),
                                .result(tckc_gap_top));
                                
simple_multiplexer #(WIDTH) mult(   .dataa(tckc_top),
                                    .datab(tckc_gap_top),
                                    .sel(gap_point),
                                    .out(tckc_actial_top));

endmodule

module hwag_cap_extrapolation #(parameter WIDTH=1) (gap,cap0,cap1,out);
input wire gap;
input wire [WIDTH-1:0] cap0,cap1;
output wire [WIDTH-1:0] out;
wire [WIDTH-1:0] extrapolation;

integer_subtraction #(WIDTH) sub(   .minuend({cap0[WIDTH-2:0],1'b0}),
                                    .subtrahend(cap1),
                                    .result(extrapolation));
                                    
simple_multiplexer #(WIDTH) mult(   .dataa(extrapolation),
                                    .datab(cap0),
                                    .sel(gap),
                                    .out(out));

endmodule

module angle_normalization #(parameter WIDTH=1) (in,max,out);

input wire [WIDTH-1:0] in;
input wire [WIDTH-1:0] max;
output wire[WIDTH-1:0] out;
wire [WIDTH-1:0] in_corrected;

integer_subtraction #(WIDTH) sub(   .minuend(in),
                                    .subtrahend(max),
                                    .result(in_corrected));
                                    
compare #(WIDTH) comp ( .dataa(in),
                        .datab(max),
                        .ageb(calc_out_ge_max));
                        
simple_multiplexer #(WIDTH) mult(   .dataa(in),
                                    .datab(in_corrected),
                                    .sel(calc_out_ge_max),
                                    .out(out));

endmodule

module angle_counter_normalization #(parameter WIDTH=1) (in,shift,max,out);
input wire [WIDTH-1:0] in;
input wire [WIDTH-1:0] shift;
input wire [WIDTH-1:0] max;
output wire [WIDTH-1:0] out;
wire [WIDTH-1:0] calc_out;

integer_addition #(WIDTH) add(  .argumenta(in),
                                .argumentb(shift),
                                .result(calc_out));
                                
angle_normalization #(WIDTH) normalization (.in(calc_out),.max(max),.out(out));

endmodule

`endif
