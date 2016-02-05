`include "timescale.v"

module top_level(clk_100mhz, rst, pixel_r, pixel_g, pixel_b, hsync, vsync, blank, clk, clk_n, D, dvi_rst, scl_tri, sda_tri);

	input clk_100mhz, rst;
	output hsync, vsync, blank, dvi_rst;
	output [7:0] pixel_r, pixel_g, pixel_b;
	output [11:0] D;
	output clk, clk_n;
	inout scl_tri, sda_tri;

	wire sda, scl;
	wire clk_100mhz_buf, clk_25mhz;
	wire locked_dcm;
	wire rom_en, fifo_rd_en, fifo_wr_en, fifo_full, fifo_empty;
	wire [12:0] rom_addr;
	wire [23:0] rom_data, fifo_data_in, fifo_data_out;

	assign clk = clk_25mhz;
	assign clk_n = ~clk_25mhz;
	assign dvi_rst = ~(rst|~locked_dcm);
	assign D = (clk)? {pixel_g[3:0], pixel_b} : {pixel_r, pixel_g[7:4]};
	assign sda_tri = (sda)? 1'bz: 1'b0;
	assign scl_tri = (scl)? 1'bz: 1'b0;
	
	clkgen clkgen_25mhz(.CLKIN_IN(clk_100mhz),
												.RST_IN(rst_n),
												.CLKDV_OUT(clk_25mhz),
												.CLK0_OUT(clk_100mhz_buf),
												.LOCKED_OUT(locked_dcm)
												);

	dvi_ifc u_dvi(  .Clk(clk_25mhz),
                    .Reset_n(dvi_rst),
                    .SDA(sda),
                    .SCL(scl),
                    .Done(),
                    .IIC_xfer_done(),
                    .init_IIC_xfer (1'b0)
                );

	rom rom_vga(.addra(rom_addr),
							.clka(clk_100mhz_buf),
							.ena(rom_en),
							.douta(rom_data)
							);
							
	fifo xclk_fifo(.rd_clk(clk_25mhz),
							.wr_clk(clk_100mhz_buf),
							.rst(rst),
							.rd_en(fifo_rd_en),
							.wr_en(fifo_wr_en),
							.din(fifo_data_in),
							.dout(fifo_data_out),
							.full(fifo_full),
							.empty(fifo_empty)
						);

	 display_plane display(.clk(clk_100mhz_buf),
												.rst_n(rst),
												.addr_out(rom_addr), //to ROM
												.read_mem(rom_en), //to ROM
												.data_in(rom_data), //from ROM
												.data_out(fifo_data_in), // to FIFO
												.wr_en(fifo_wr_en), //to FIFO
												.fifo_full(fifo_full), //from FIFO
												.fifo_empty(fifo_empty) //from FIFO
												);
endmodule
