`timescale 1us/1us

`include "hwag.sv"

module test();
reg clk,ram_clk,rst,we,re,vr;
reg [7:0] addr;
inout [15:0] data;
reg [15:0] w_data;
assign data = w_data;

hwag hwag0 (.clk(clk),.rst(rst),.ssram_we(we),.ssram_re(re),.ssram_addr(addr),.ssram_data(data),.vr_in(vr),.vr_out(vr_out));

always @(posedge ram_clk) begin
    if(addr < 63) begin 
        if(we) begin
            case(addr)
                0: w_data <= 16'd3;
                default: w_data <= 16'd0;
            endcase
        end
        addr <= addr + 1'b1;
    end else begin
        addr <= 8'd0;
        w_data <= 16'bZ;
        we <= 1'b0;
        re <= 1'b1;
    end
end

always #10 clk <= ~clk;
always #30 ram_clk <= ~ram_clk;
always #100 vr <= ~vr;
always #10 rst <= 1'b0;

integer ssram_i;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);

    for(ssram_i = 0; ssram_i < 64; ssram_i = ssram_i + 1) begin
        $dumpvars(1, hwag0.ssram_out[ssram_i]);
    end
    
    clk <= 1'b0;
    ram_clk <= 1'b0;
    vr <= 1'b0;
    rst <= 1'b1;
    
    we <= 1'b1;
    re <= 1'b0;
    addr <= 8'd0;
    w_data <= 16'b1;
    
    #10000 $finish();
end

endmodule
