module display_tb();

reg clk, rst_n, fifo_full, fifo_empty;
reg [23:0] data_in;
wire [12:0] addr_out;
wire [23:0] data_out;
wire read_mem, wr_en;

display_plane display(.clk(clk),
                    .rst_n(rst_n),
                    .addr_out(addr_out),
                    .read_mem(read_mem),
                    .data_in(data_in),
                    .data_out(data_out),
                    .wr_en(wr_en),
                    .fifo_full(fifo_full),
                    .fifo_empty(fifo_empty)
                    );

initial begin
clk = 1'b0;
rst_n = 1'b0;
fifo_empty = 1'b1;
fifo_full = 1'b0;
data_in = 24'hf0f;
#10 rst_n = 1'b1;
end

always #5 clk=~clk;

endmodule
