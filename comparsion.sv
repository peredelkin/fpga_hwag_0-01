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

`endif
