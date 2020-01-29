`ifndef COUNTING_V
`define COUNTING_V

module counter #(parameter WIDTH=1)
                (clk,rst,sload,ena,srst,data_load,data_out);
input wire clk,rst,sload,ena,srst;
input wire [WIDTH-1:0] data_load;
output reg [WIDTH-1:0] data_out;
initial data_out <= 0;
	always @(posedge clk,posedge rst) begin
		if(rst) begin
			data_out <= 0;
		end else begin
			if(srst) begin
				data_out <= 0;
			end else begin
				if(sload) begin
					data_out <= data_load;
				end else begin
					if(ena) begin
						data_out <= data_out + 1'b1;
					end
				end
			end
		end
	end
endmodule


module counter_compare #(parameter WIDTH=1) (clk,ena,rst,srst,sload,dload,dout,dtop,out_e_top,out_g_top,out_l_top,out_ne_top,out_ge_top,out_le_top);
input wire clk,ena,rst,srst,sload;
output wire out_e_top,out_g_top,out_l_top,out_ne_top,out_ge_top,out_le_top;
input wire [WIDTH-1:0] dload;
output wire [WIDTH-1:0] dout;
input wire [WIDTH-1:0] dtop;
counter #(WIDTH) cnt(.clk(clk),.rst(rst),.sload(sload),.ena(ena),.srst(srst),.data_load(dload),.data_out(dout));
compare #(WIDTH) cmp(.dataa(dout),.datab(dtop),.aeb(out_e_top),.agb(out_g_top),.alb(out_l_top),.aneb(out_ne_top),.ageb(out_ge_top),.aleb(out_le_top));
endmodule

`endif