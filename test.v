`timescale 1us/1us

`include "hwag.sv"

module test();
reg clk,ram_clk,rst,we,re,vr,cam,cam_phase,spi_clk,spi_din;
reg [7:0] scnt;
reg [7:0] scnt_top;
reg [7:0] tckc;
reg [7:0] tckc_top;
reg [7:0] tcnt;

reg [7:0] addr;
inout [15:0] data;
reg [15:0] w_data;
assign data = w_data;

wire [7:0] spi_bus_out;
spi_slave spi_slave0
            (   .spi_in(spi_out),
                .spi_out(spi_out),
                .spi_clk(spi_clk),
                .spi_ss(1'b0),
                .spi_clk_polarity(1'b0),
                .spi_clk_phase(1'b0),
                .clk(clk),
                .rst(rst),
                .ena(1'b1),
                .bus_in(8'd129),
                .bus_out(spi_bus_out));

hwag hwag0  (   .clk(clk),
                .cap_in(vr),
                .cap_out(vr_out),
                .led1_out(led1),
                .led2_out(led2),
                .coil14_out(coil));

always @(posedge ram_clk) begin
    if(addr < 131) begin 
        if(we) begin
            case(addr)
                0: w_data <= 16'd128; // MIN CAP L
                1: w_data <= 16'd0; //MIN CAP H
                2: w_data <= 16'd65535; // MAX CAP L
                3: w_data <= 16'd0; //MAX CAP H
                4: w_data <= 16'd57; //HWATHNB
                5: w_data <= 16'd4; //HWASTWD
                6: w_data <= 16'd3839; //HWAATOPL
                
                63: w_data <= 16'b111; //HWACR0
                65: w_data <= 16'b10; //pcnt ovf ie
                70: w_data <= 16'd2; //HWATHVL
                
                127: w_data <= 16'd1024; //HWAIGNCHRGL
                129: w_data <= 16'd3830; //HWAIGNANGL
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
    if(scnt == scnt_top) begin
        scnt <= 8'd0;
        if(tckc == tckc_top) begin
            tckc <= 8'd0;
            vr <= 1'b0;
            if(tcnt == 57) begin
                tcnt <= 8'd0;
                tckc_top <= 8'd63;
            end else begin
                
                if(tcnt == 30) begin
                    cam_phase <= ~cam_phase;
                end
    
                if(cam_phase) begin
                    if(tcnt == 54) begin
                        cam <= 1'b0;
                    end
                    if(tcnt == 4) begin
                        cam <= 1'b1;
                    end
                end
                
                if(tcnt == 56) begin
                    tckc_top <= 8'd191;
                end
                scnt_top <= scnt_top + 8'd1;
                tcnt <= tcnt + 8'd1;
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
always #10 spi_clk <= ~spi_clk;
always #80 spi_din <= ~spi_din;
always #2 ram_clk <= ~ram_clk;
always #2 rst <= 1'b0;

//integer ssram_i;

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test);

    //for(ssram_i = 0; ssram_i < 64; ssram_i = ssram_i + 1) begin
    //    $dumpvars(1, hwag0.ssram_out[ssram_i]);
    //end
    
    scnt <= 8'd0;
    scnt_top <= 8'd3;
    tckc <= 8'd0;
    tckc_top <= 8'd63;
    tcnt <= 8'd45;
    cam <= 1'b1;
    cam_phase <= 1'b0;
    
    spi_clk <= 1'b0;
    spi_din <= 1'b0;
    
    clk <= 1'b0;
    ram_clk <= 1'b0;
    vr <= 1'b0;
    rst <= 1'b1;
    
    we <= 1'b1;
    re <= 1'b0;
    addr <= 8'd0;
    w_data <= 16'd3; // addr 0: значение фильтра
    
    #10000 $finish();
end

endmodule
