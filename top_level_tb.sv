`include "timescale.v"
module top_level_tb();
reg clk_100mhz, rst;
wire [7:0] pixel_r, pixel_g, pixel_b;
wire blank, hsync, vsync, clk, clk_n, dvi_rst, scl_tri, sda_tri;
wire [11:0] D;

top_level_sim top(.clk_100mhz(clk_100mhz),
                .rst(rst),
                .pixel_r(pixel_r),
                .pixel_g(pixel_g),
                .pixel_b(pixel_b),
                .hsync(hsync),
                .vsync(vsync),
                .blank(blank),
                .clk(clk),
                .clk_n(clk_n),
                .D(D),
                .dvi_rst(dvi_rst),
                .scl_tri(scl_tri),
                .sda_tri(sda_tri)
                );

initial begin
clk_100mhz = 1'b0;
rst = 1'b1;
top.sim_cnt = 2'b0;
#50 rst = 1'b0;
end

always #5 clk_100mhz = ~clk_100mhz;

endmodule
