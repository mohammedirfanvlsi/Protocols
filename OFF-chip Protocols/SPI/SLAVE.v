module spi_slave #(
  parameter CPOL = 0,
  parameter CPHA = 0
)(
  input  wire       sclk,
  input  wire       cs_n,
  input  wire       rst_n,     // ✅ added reset
  input  wire       mosi,
  input  wire [7:0] tx_data,
  output reg        miso,
  output reg [7:0]  rx_data
);

  reg [7:0] tx_shift;
  reg [7:0] rx_shift;
  reg [2:0] bit_cnt;

  wire sample_edge = (CPHA == 0) ?  sclk : ~sclk;
  wire shift_edge  = (CPHA == 0) ? ~sclk :  sclk;

  /* ✅ Reset + Load data at CS falling edge */
  always @(negedge cs_n or negedge rst_n) begin
    if (!rst_n) begin
      bit_cnt  <= 3'd0;
      tx_shift <= 8'd0;
      rx_shift <= 8'd0;
    end else begin
      bit_cnt  <= 3'd7;
      tx_shift <= tx_data;
      rx_shift <= 8'd0;
    end
  end

  /* SPI clocking */
  always @(posedge sclk or negedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      miso <= 1'b0;
    end else if (!cs_n) begin

      /* Shift out */
      if (shift_edge) begin
        miso     <= tx_shift[7];
        tx_shift <= tx_shift << 1;
      end

      /* Shift in */
      if (sample_edge) begin
        rx_shift <= {rx_shift[6:0], mosi};
        bit_cnt  <= bit_cnt - 1;
      end

    end
  end

  /* ✅ Reset + latch RX when CS goes high */
  always @(posedge cs_n or negedge rst_n) begin
    if (!rst_n)
      rx_data <= 8'd0;
    else
      rx_data <= rx_shift;
  end

endmodule
