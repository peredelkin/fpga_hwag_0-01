`ifndef COMPARISON_V
`define COMPARISON_V

module compare #(parameter WIDTH=1)
                (dataa,datab,aeb,agb,alb,aneb,ageb,aleb);
input wire [WIDTH-1:0] dataa;
input wire [WIDTH-1:0] datab;
output reg aeb,agb,alb;
output wire aneb,ageb,aleb;
not(aneb,aeb);
//or(ageb,agb,aeb);
//or(aleb,alb,aeb);
not(ageb,alb);
not(aleb,agb);
	always @(*) begin
		if(dataa == datab) begin
			aeb <= 1'b1;
		end else begin
			aeb <= 1'b0;
		end
		
		if(dataa > datab) begin
			agb <= 1'b1;
		end else begin
			agb <= 1'b0;
		end
		
		if(dataa < datab) begin
			alb <= 1'b1;
		end else begin
			alb <= 1'b0;
		end
	end
endmodule

module period_normal #(parameter WIDTH=1) (min,max,cap0,cap1,cap2,less_max,more_min);
output wire less_max,more_min;
input wire [WIDTH-1:0] min;
input wire [WIDTH-1:0] max;
input wire [WIDTH-1:0] cap0;
input wire [WIDTH-1:0] cap1;
input wire [WIDTH-1:0] cap2;
compare #(WIDTH) cap0_less_max_comp(.dataa(cap0),.datab(max),.alb(cap0_less_max));
compare #(WIDTH) cap1_less_max_comp(.dataa(cap1),.datab(max),.alb(cap1_less_max));

compare #(WIDTH) cap0_more_min_comp(.dataa(cap0),.datab(min),.agb(cap0_more_min));
compare #(WIDTH) cap1_more_min_comp(.dataa(cap1),.datab(min),.agb(cap1_more_min));
compare #(WIDTH) cap2_more_min_comp(.dataa(cap2),.datab(min),.agb(cap2_more_min));
or(less_max,cap0_less_max,cap1_less_max); //0 если два захвата подряд больше максимального
and(more_min,cap0_more_min,cap1_more_min,cap2_more_min); //1 если период захвата больше минимального
endmodule

module gap_search #(parameter WIDTH=1) (cap0,cap1,cap2,gap);
input wire [WIDTH-1:0] cap0;
input wire [WIDTH-1:0] cap1;
input wire [WIDTH-1:0] cap2;
wire [WIDTH-1:0] half_cap1 = {1'b0,cap1[WIDTH-1:1]};
output wire gap;
and(gap,cap0_less_half_cap1,cap2_less_half_cap1);
compare #(WIDTH) cap0_less_half_cap1_comp (.dataa(cap0),.datab(half_cap1),.alb(cap0_less_half_cap1));
compare #(WIDTH) cap2_less_half_cap1_comp (.dataa(cap2),.datab(half_cap1),.alb(cap2_less_half_cap1));
endmodule

module gap_run_check #(parameter WIDTH=1) (cap0,pcnt,gap);
input wire [WIDTH-1:0] cap0;
input wire [WIDTH-1:0] pcnt;
output wire gap;
wire double_cap0_l_pcnt;
assign gap = double_cap0_l_pcnt;
wire [WIDTH-1:0] double_cap0 = {cap0[WIDTH-2:0],1'b0};
compare #(WIDTH) double_cap0_le_pcnt_comp(.dataa(double_cap0),.datab(pcnt),.alb(double_cap0_l_pcnt));
endmodule

`endif
