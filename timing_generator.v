`include "timescale.v"

module timing_generator(input clk, //25mhz
                        input rst_n,
                        input fifo_empty,
                        input [23:0] data_in,
                        output fifo_read,
                        output [7:0] pixel_r,
                        output [7:0] pixel_g,
                        output [7:0] pixel_b,
                        output reg hsync,
                        output reg vsync
                        );

localparam IDLE=3'b000, FRONT_PORCH=3'b001, SYNC=3'b010, BACK_PORCH=3'b011, ACTIVE=3'b100;
reg [2:0] horz_st, horz_nxt_st, vert_st, vert_nxt_st;
reg [9:0] horz_cnt, vert_cnt;
reg inc_vert;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        horz_cnt <= 10'b0;
    end else begin
        if(horz_cnt == 799)
            horz_cnt <= 10'b0;
        else if(!fifo_empty)
            horz_cnt <= horz_cnt +1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        vert_cnt <= 10'b0;
    end else begin
        if(vert_cnt == 524)
            vert_cnt <= 10'b0;
        else if(inc_vert)
            vert_cnt <= vert_cnt +1;
    end
end

assign fifo_read = (horz_st == ACTIVE && vert_st == ACTIVE) ? 1'b1 : 1'b0;
assign pixel_r = (horz_st == ACTIVE && vert_st == ACTIVE) ? data_in[23:16] : 8'b0;
assign pixel_g = (horz_st == ACTIVE && vert_st == ACTIVE) ? data_in[15:8] : 8'b0;
assign pixel_b = (horz_st == ACTIVE && vert_st == ACTIVE) ? data_in[7:0] : 8'b0;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        horz_st <= IDLE;
    end else begin
        horz_st <= horz_nxt_st;
    end
end

always @(*) begin
hsync = 1'b1;
inc_vert = 1'b0;
    case (horz_st)
        IDLE:
            if(!fifo_empty) begin
                horz_nxt_st = FRONT_PORCH;
            end else begin
                horz_nxt_st = IDLE;
            end
        FRONT_PORCH:
            if(horz_cnt == 15) begin //16 cycles
                horz_nxt_st = SYNC;
            end else begin
                horz_nxt_st = FRONT_PORCH;
            end
        SYNC:
            if(horz_cnt == 111) begin //96 cycles
                horz_nxt_st = BACK_PORCH;
            end else begin
                hsync = 1'b0;
                horz_nxt_st = SYNC;
            end
        BACK_PORCH:
            if(horz_cnt == 159) begin //48 cycles
                horz_nxt_st = ACTIVE;
            end else begin
                horz_nxt_st = BACK_PORCH;
            end
        ACTIVE:
            if(horz_cnt == 799) begin //640 cycles
                inc_vert = 1'b1;
                horz_nxt_st = FRONT_PORCH;
            end else begin
                horz_nxt_st = ACTIVE;
            end
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        vert_st <= IDLE;
    end else begin
        vert_st <= vert_nxt_st;
    end
end

always @(*) begin
vsync = 1'b1;
    case (vert_st)
        IDLE:
            if(!fifo_empty) begin
                vert_nxt_st = FRONT_PORCH;
            end else begin
                vert_nxt_st = IDLE;
            end
        FRONT_PORCH:
            if(vert_cnt == 9) begin //10 cycles
                vert_nxt_st = SYNC;
            end else begin
                vert_nxt_st = FRONT_PORCH;
            end
        SYNC:
            if(vert_cnt == 11) begin //2 cycles
                vert_nxt_st = BACK_PORCH;
            end else begin
                vsync = 1'b0;
                vert_nxt_st = SYNC;
            end
        BACK_PORCH:
            if(vert_cnt == 44) begin //45 cycles
                vert_nxt_st = ACTIVE;
            end else begin
                vert_nxt_st = BACK_PORCH;
            end
        ACTIVE:
            if(vert_cnt == 524) begin //480 cycles
                vert_nxt_st = FRONT_PORCH;
            end else begin
                vert_nxt_st = ACTIVE;
            end
    endcase
end

endmodule
