module spi_top #(
  parameter CPOL = 0,
  parameter CPHA = 0
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire       start,
  input  wire [7:0] master_tx_data,
  input  wire [7:0] slave_tx_data,
  output wire [7:0] master_rx_data,
  output wire [7:0] slave_rx_data,
  output wire       busy
);

  wire sclk;
  wire mosi;
  wire miso;
  wire cs_n;

  assign cs_n = ~busy;   // slave selected while busy

  // -------- MASTER --------
  spi_master #(
    .CPOL(CPOL),
    .CPHA(CPHA)
  ) u_master (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (start),
    .tx_data (master_tx_data),
    .miso    (miso),
    .sclk    (sclk),
    .mosi    (mosi),
    .rx_data (master_rx_data),
    .busy    (busy)
  );

  // -------- SLAVE --------
  spi_slave #(
    .CPOL(CPOL),
    .CPHA(CPHA)
  ) u_slave (
    .sclk    (sclk),
    .rst_n   (rst_n),
    .cs_n    (cs_n),
    .mosi    (mosi),
    .tx_data (slave_tx_data),
    .miso    (miso),
    .rx_data (slave_rx_data)
  );

endmodule
