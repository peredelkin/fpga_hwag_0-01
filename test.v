`timescale 1us/1us

`include "hwag.sv"

module test();
reg clk,ram_clk,rst,we,re,vr;
reg [7:0] scnt;
reg [7:0] tckc;
reg [7:0] tckc_top;
reg [7:0] tcnt;

reg [7:0] addr;
inout [15:0] data;
reg [15:0] w_data;
assign data = w_data;

hwag hwag0 (    .clk(clk),
                .rst(rst),
                .ssram_we(we),
                .ssram_re(re),
                .ssram_addr(addr),
                .ssram_data(data),
                .vr_in(vr),
                .vr_out(vr_out),
                .hwagif(hwagif));

always @(posedge ram_clk) begin
    if(addr < 70) begin 
        if(we) begin
            case(addr)
                63: w_data <= 16'b111; //addr 64; HWACR0
                65: w_data <= 16'b10; //pcnt ovf ie
                default: w_data <= 16'd0;
            endcase
        end
        if(we | re) addr <= addr + 1'b1;
    end else begin
        if(re) begin
            //re <= 1'b0;
            addr <= 8'd0;
        end else begin
            if (we) begin
                w_data <= 16'bZ;
                we <= 1'b0;
                re <= 1'b1;
                addr <= 8'd0;
            end
        end
    end
end

always @(posedge clk) begin
    if(scnt == 3) begin
        scnt <= 8'd0;
        if(tckc == tckc_top) begin
            tckc <= 8'd0;
            vr <= 1'b0;
            if(tcnt == 57) begin
                tcnt <= 8'd0;
                tckc_top <= 8'd191;
            end else begin
                tcnt <= tcnt + 8'd1;
                tckc_top <= 8'd63;
            end
        end else begin
            if(tckc == (tckc_top/2)) begin
                vr <= 1'b1;
            end
            tckc <= tckc + 8'd1;
        end
    end else begin
        scnt <= scnt + 8'd1;
    end
end

always #1 clk <= ~clk;
always #2 ram_clk <= ~ram_clk;
always #1 rst <= 1'b0;

integer ssram_i;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);

    for(ssram_i = 0; ssram_i < 64; ssram_i = ssram_i + 1) begin
        $dumpvars(1, hwag0.ssram_out[ssram_i]);
    end
    
    scnt <= 8'b0;
    tckc <= 8'b0;
    tckc_top <= 8'd63;
    tcnt <= 8'b0;
    
    clk <= 1'b0;
    ram_clk <= 1'b0;
    vr <= 1'b0;
    rst <= 1'b1;
    
    we <= 1'b1;
    re <= 1'b0;
    addr <= 8'd0;
    w_data <= 16'd3; // addr 0: значение фильтра
    
    #100000 $finish();
end

endmodule
