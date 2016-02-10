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
	
        //USED FOR SIMULATION
        /*
        reg [1:0] sim_cnt;
        always@(posedge clk_100mhz)
            sim_cnt <= sim_cnt +1; //this will be forced to zero by the TB
        assign clk_25mhz = sim_cnt[1];
        assign locked_dcm = rst;
        assign clk_100mhz_buf = clk_100mhz;
        */

	clkgen clkgen_25mhz(.CLKIN_IN(clk_100mhz),
			.RST_IN(rst),
			.CLKDV_OUT(clk_25mhz),
			.CLK0_OUT(clk_100mhz_buf),
			.LOCKED_OUT(locked_dcm)
                        );

        //USED FOR SIMULATION
/*
	simple_rom rom_vga(.addr(rom_addr),
		        .clk(clk_100mhz_buf),
		        .rd_en(rom_en),
		        .rdata(rom_data)
		);
                */
	rom rom_vga(.addra(rom_addr),
		.clka(clk_100mhz_buf),
		.ena(rom_en),
		.douta(rom_data)
		);
							
	 display_plane display(.clk(clk_100mhz_buf),
				.rst_n(!rst),
				.addr_out(rom_addr), //to ROM
				.read_mem(rom_en), //to ROM
				.data_in(rom_data), //from ROM
				.data_out(fifo_data_in), // to FIFO
				.wr_en(fifo_wr_en), //to FIFO
				.fifo_full(fifo_full), //from FIFO
				.fifo_empty(fifo_empty) //from FIFO
			        );
        //USED FOR SIMULATION
         /*
         aFifo fifo(.Data_out(fifo_data_out),
                    .Empty_out(fifo_empty),
                    .ReadEn_in(fifo_rd_en),
                    .RClk(clk_25mhz),
                    .Data_in(fifo_data_in),
                    .Full_out(fifo_full),
                    .WriteEn_in(fifo_wr_en),
                    .WClk(clk_100mhz_buf),
                    .Clear_in(!rst)
                    );
         */
         
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

         //the signal blank has the same functionality as the signal fifo_rd_en that we're using
         assign blank = fifo_rd_en;

         timing_generator timegen(.clk(clk_25mhz),
                                .rst_n(!rst),
                                .fifo_empty(fifo_empty),
                                .data_in(fifo_data_out),
                                .fifo_read(fifo_rd_en),
                                .pixel_r(pixel_r),
                                .pixel_g(pixel_g),
                                .pixel_b(pixel_b),
                                .hsync(hsync),
                                .vsync(vsync)
                                );

	dvi_ifc u_dvi(.Clk(clk_25mhz),
                    .Reset_n(dvi_rst),
                    .SDA(sda),
                    .SCL(scl),
                    .Done(),
                    .IIC_xfer_done(),
                    .init_IIC_xfer (1'b0)
                    );
endmodule
