module receiver #(
  parameter data_width = 8
)(
  input clk, rst,
  input rx,
  input rx_tick,
  output reg done,
  output reg [data_width-1:0] data_out
);

  reg [data_width-1:0] shift_reg;
  reg [3:0] bit_count;
  reg [3:0] tick_count;

  parameter IDLE=0, START=1, DATA=2, STOP=3;
  reg [1:0] state;

  always @(posedge clk or negedge rst) begin
    if(!rst) begin
      state <= IDLE;
      done <= 0;
      data_out <= 0;
      bit_count <= 0;
      tick_count <= 0;
    end
    else if(rx_tick) begin
      done <= 0;

      case(state)

        IDLE: begin
          if(rx == 0) begin
            tick_count <= 0;
            state <= START;
          end
        end

        START: begin
          if(tick_count == 7) begin
            tick_count <= 0;
            bit_count <= 0;
            state <= DATA;
          end
          else tick_count <= tick_count + 1;
        end

        DATA: begin
          if(tick_count == 15) begin
            shift_reg <= shift_reg >> 1;
             shift_reg[data_width-1] <= rx;
            tick_count <= 0;
            if(bit_count == data_width-1)
              state <= STOP;
            else
              bit_count <= bit_count + 1;
          end
          else tick_count <= tick_count + 1;
        end

        STOP: begin
          if(tick_count == 15) begin
            data_out <= shift_reg;
            done <= 1;
            state <= IDLE;
          end
          else tick_count <= tick_count + 1;
        end

      endcase
    end
  end
endmodule