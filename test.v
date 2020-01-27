`timescale 1us/1us

`include "hwag.sv"

module test();
reg clk,ram_clk,rst,we,re;
reg [7:0] addr;
inout [15:0] data;
reg [15:0] w_data;
assign data = w_data;

hwag hwag0 (.clk(clk),.rst(rst),.ssram_we(we),.ssram_re(re),.ssram_addr(addr),.ssram_data(data));

always @(posedge ram_clk) begin
    if(addr < 7) begin 
        if(we) w_data <= w_data + 2'd2;
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
always #20 rst <= 1'b0;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);

    clk <= 1'b0;
    ram_clk <= 1'b0;
    rst <= 1'b1;
    
    we <= 1'b1;
    re <= 1'b0;
    addr <= 8'd0;
    w_data <= 16'b0;
    
    #1000 $finish();
end

endmodule
