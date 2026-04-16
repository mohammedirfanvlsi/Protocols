module transmitter #(
  parameter data_width = 8
)(
  input clk, rst,
  input tx_en,
  input tx_tick,
  input [data_width-1:0] data_in,
  output reg tx,
  output busy
);

  reg [data_width-1:0] shift_reg;
  reg [3:0] bit_count;

  parameter IDLE=0, START=1, DATA=2, STOP=3;
  reg [1:0] state;

  always @(posedge clk or negedge rst) begin
    if(!rst) begin
      state <= IDLE;
      tx <= 1;
      bit_count <= 0;
    end
    else if(tx_tick) begin
      case(state)

        IDLE: begin
          tx <= 1;
          if(tx_en) begin
            shift_reg <= data_in;
            state <= START;
          end
        end

        START: begin
          tx <= 0;
          bit_count <= 0;
          state <= DATA;
        end

        DATA: begin
          tx <= shift_reg[0];
          shift_reg <= shift_reg >> 1;   
          if(bit_count == data_width-1)
            state <= STOP;
          else
            bit_count <= bit_count + 1;
        end

        STOP: begin
          tx <= 1;
          state <= IDLE;
        end

      endcase
    end
  end

  assign busy = (state != IDLE);

endmodule
