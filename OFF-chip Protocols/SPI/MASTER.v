module spi_master #(
  parameter CPOL = 0,
  parameter CPHA = 0
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire       start,
  input  wire [7:0] tx_data,
  input  wire       miso,
  output reg        sclk,
  output reg        mosi,
  output reg [7:0]  rx_data,
  output reg        busy
);

  reg [7:0] tx_shift, rx_shift;
  reg [2:0] bit_cnt;
  reg       done_pending;

  wire sample_edge = (CPHA == 0) ?  sclk : ~sclk;
  wire shift_edge  = (CPHA == 0) ? ~sclk :  sclk;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sclk <= CPOL;
      busy <= 0;
      done_pending <= 0;
      rx_data <= 0;
    end else begin

      if (start && !busy) begin
        busy <= 1;
        bit_cnt <= 3'd7;
        tx_shift <= tx_data;
        rx_shift <= 0;
        sclk <= CPOL;
        done_pending <= 0;
      end

      else if (busy) begin
        sclk <= ~sclk;

        if (shift_edge)
          mosi <= tx_shift[bit_cnt];

        if (sample_edge) begin
          rx_shift[bit_cnt] <= miso;

          if (bit_cnt == 0)
            done_pending <= 1;
          else
            bit_cnt <= bit_cnt - 1;
        end

        if (done_pending && shift_edge) begin
          rx_data <= rx_shift;
          busy <= 0;
          sclk <= CPOL;
          done_pending <= 0;
        end
      end
    end
  end
endmodule
