`include "timescale.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:41:58 02/10/2014 
// Design Name: 
// Module Name:    simple_rom 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module simple_rom(clk, addr, rd_en, rdata);
  parameter ADDR_WIDTH = 13;
  parameter DATA_WIDTH = 24;
  parameter ROM_DATA_FILE = "numbers.mem";
    input clk;
    input rd_en;
    input [ADDR_WIDTH-1:0] addr;
    output reg [DATA_WIDTH-1:0] rdata;

    reg [DATA_WIDTH-1:0] MY_ROM [0:2**ADDR_WIDTH-1];
    initial $readmemh(ROM_DATA_FILE, MY_ROM);
    always@(posedge clk) 
        if(rd_en)
            rdata <= MY_ROM[addr];

endmodule
