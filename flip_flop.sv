
`ifndef FLIP_FLOP_SV
`define FLIP_FLOP_SV

module rs_ff (set,reset,clk,rst,ena,q);
input wire set,reset,clk,rst,ena;
output reg q;
initial q <= 0;
always @(posedge clk,posedge rst) begin
	if(rst) begin
		q <= 0;
	end else begin
		if(ena) begin
			if(reset) begin
				q <= 0;
			end else begin
				if(set) begin
					q <= 1;
				end else begin
					q <= q;
				end
			end
		end
	end
end
endmodule

module d_ff_wide #(parameter WIDTH=1) (d,clk,rst,ena,q);
input wire clk,rst,ena;
input wire [WIDTH-1:0] d;
output reg [WIDTH-1:0] q;
initial q <= 0;
always @(posedge clk,posedge rst) begin
    if(rst) begin
        q <= 0;
    end else begin
        if(ena) begin
            q <= d;
        end
    end
end
endmodule

module d_shift_left_load #(parameter WIDTH=1)
                    (d,clk,rst,sshift,sload,load_data,q);
input wire d,clk,rst,sload,sshift;
input wire [WIDTH-1:0] load_data;
output reg [WIDTH-1:0] q;
always @(posedge clk,posedge rst) begin
    if(rst) begin
        q <= 0;
    end else begin
        if(sload) begin
            q <= load_data;
        end else begin
            if(sshift) begin
                q <= {q[WIDTH-2:0],d};
            end
        end
    end
end
endmodule

module latch_user #(parameter WIDTH=1)
                    (d,l,q);

input wire [WIDTH-1:0] d;
input wire l;
output reg [WIDTH-1:0] q;

always @(*) begin
    if(l) begin
        q <= q;
    end else begin
        q <= d;
    end
end

endmodule

//module d_ff_load_wide #(parameter WIDTH=1) (d,clk,rst,ena,ld,dld,q);
//endmodule

`endif
