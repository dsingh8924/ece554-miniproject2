module time_gen(input clk, input [23:0]data_in, output [23:0]data_out, output reg h_sync, v_sync);

  localparam FRONTPORCH = 2'b00;
  localparam SYNCH = 2'b01;
  localparam BACKPORCH = 2'b11;
  localparam ACTIVE = 2'b10;

  reg [23:0]clk_60hz; //clk for vertical scan refreash rate
  reg [11:0]clk_31khz; //clk for horizontal scan refresh rate
  reg [1:0]stateh, nxt_stateh;
  reg [1:0]statev, nxt_statev;
  reg go_synch, go_front, go_back, go_active;

  //state register
  always@(posedge clk) begin
    stateh <= nxt_stateh;
    statev <= nxt_statev;
  end

  //counter to determine when the vertical scan refreshes
  always@(posedge clk) begin
    if(clk_60hz == 24'h000000) begin
      clk_60hz <= 24'h196E6A;
    end else begin
      clk_60hz <= clk_60hz - 1'b1;
    end
  end

  //counter to determine when the horizontal scan refreshes
  always@(posedge clk) begin
    if(clk_31khz == 12'b00) begin
      clk_31khz <= 12'hC69;
      go_front <= 1'b1;
    end else begin
      go_front <= 1'b0;
      go_synch <= 1'b0;
      go_back <= 1'b0;
      go_active <= 1'b0;
      if(clk_31khz == 12'hC2A) begin
        go_synch <= 1'b1;
      end else if(clk_31khz == 12'hAAD) begin
        go_back <= 1'b1;
      end else if(clk_31khz == 12'h9EF) begin
        go_active <= 1'b1;
      end
      clk_31khz <= clk_60hz - 1'b1;
    end
  end

  //state machine for horizontal timing
  always@(*) begin
    casex(stateh)
                FRONTPORCH: begin
                              if(go_synch) begin
                                nxt_stateh <= SYNCH;
                              end else begin
                                nxt_stateh <= FRONTPORCH;
                              end
                            end
                SYNCH: begin
                        if(go_back) begin
                          nxt_stateh <= BACKPORCH;
                          h_sync <= 1'b0;
                        end else begin
                          h_sync <= 1'b1;
                          nxt_stateh <= SYNCH;
                        end
                      end
                BACKPORCH: begin
                             if(go_active) begin
                               nxt_stateh <= ACTIVE;
                             end else begin
                               nxt_stateh <= BACKPORCH;
                             end
                           end
                ACTIVE: begin
                          if(go_front) begin 
                            nxt_stateh <= FRONTPORCH;
                          end else begin
                            nxt_stateh <= ACTIVE;
                          end
                        end
                default: nxt_stateh <= 2'bxx;
    endcase
  end

  
  //state machine for vertical timing
  always@(*) begin
    casex(statev)
                FRONTPORCH: begin
                              nxt_statev <= SYNCH;
                            end
                SYNCH: begin 
                        nxt_statev <= BACKPORCH;
                        v_sync <= 1'b1;
                      end
                BACKPORCH: begin
                             nxt_statev <= ACTIVE;
                           end
                ACTIVE: begin 
                          nxt_statev <= FRONTPORCH;
                        end
                default: nxt_statev <= 2'bxx;
    endcase
  end

  

endmodule
