`include "timescale.v"

module display_plane(input clk,
                    input rst_n,
                    output [12:0] addr_out, //to the ROM (ROM size is 4800, need 13 bits)
                    output reg read_mem, //to the ROM
                    input [23:0] data_in, //from the ROM
                    output [23:0] data_out, //to FIFO
                    output reg wr_en, //to FIFO
                    input fifo_full, //from FIFO
                    input fifo_empty //from FIFO
                    );

//ROM frame size is 80x60
//pixel multiplication has to be done in this module as well

reg [2:0] horz_cnt; 
reg [12:0] curr_loc, horz_start;
wire [12:0] horz_end;

localparam IDLE=1'b0, WRITE_FIFO=1'b1;
reg st, nxt_st;

//address to the ROM is the same thing as current location
assign addr_out = curr_loc;

//data out is simply data coming in from the ROM as controlled by the state machine
assign data_out = wr_en ? data_in : 1'bz;

//3-bit counter for keeping track of horizontal replication (the image has to be repeated 8 times)
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        horz_cnt <= 3'b0;
    end else begin
        if(curr_loc == horz_end)
            horz_cnt <= horz_cnt +1;
    end
end

//we'll read ROM in chunks of 80 location at a time
//horz_start and horz_end are pointers to keep track of which horizontal line is being read
//these are incremented by 80 whenever the 3-bit counter maxes out
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
       horz_start <= 13'b0; 
    end else begin
        if((horz_cnt == 7) && (curr_loc == horz_end))
            if(curr_loc == 4799)
                horz_start <= 0;
            else
                horz_start <= horz_start +80; 
    end
end

assign horz_end = horz_start + 79;

//keeping track of current location in memory
//this pointer runs between horz_start and horz_end 8 times
//controlled by the state machine signal - read_mem
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        curr_loc <= 13'b0;
    end else begin
        if(read_mem)
            if((curr_loc == horz_end) && (horz_cnt != 7))
                curr_loc <= horz_start;
	    else if(curr_loc == 4799)
		curr_loc <= 0;
            else
                curr_loc <= curr_loc +1;
    end
end

//state machine
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

always@(*) begin
read_mem = 1'b0;
wr_en = 1'b0;
    case(st)
        IDLE:
            //whenver FIFO becomes empty, the state machine kicks off to the WRITE_FIFO state
            if(fifo_empty) begin
                //read_mem = 1'b1; //This was causing a really interesting bug
                nxt_st = WRITE_FIFO;
            end else begin
                nxt_st = IDLE;
            end
        WRITE_FIFO:
            //FIFO is written until it becomes full after which state machine waits for it to become empty in the IDLE state
            if(!fifo_full) begin
                read_mem = 1'b1;
                wr_en = 1'b1;
                nxt_st = WRITE_FIFO;
            end else begin
                nxt_st = IDLE;
            end
    endcase
end


endmodule
