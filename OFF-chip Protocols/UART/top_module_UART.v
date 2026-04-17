module uart_top #(
   parameter tx_sys_clk = 10_000_000,
  parameter rx_sys_clk = 50_000_000,
  parameter baud_rate = 9600,
  parameter data_width = 8)
(
  input tx_clk,rx_clk,
  input rst_n,
  input tx_en,
  input [7:0] data_in,
  input rx,
  output tx,
  output busy,
  output done,
  output [7:0] data_out
);

  wire tx_tick, rx_tick;

  tx_baud_generator #(.sys_clk(tx_sys_clk), .baud_rate(baud_rate))
  TX_BAUD (.clk(tx_clk), .rst_n(rst_n), .baud_en(1'b1), .tx_tick(tx_tick));

  rx_baud_generator #(.sys_clk(rx_sys_clk), .baud_rate(baud_rate))
  RX_BAUD (.clk(rx_clk), .rst_n(rst_n), .baud_en(1'b1), .rx_tick(rx_tick));

  transmitter  #(
    .data_width(8))
     TX (.clk(tx_clk), .rst_n(rst_n),
    .tx_en(tx_en),
    .tx_tick(tx_tick),
    .data_in(data_in),
    .tx(tx),
    .busy(busy)
  );

  receiver  #(
     .data_width(8))
     RX (.clk(rx_clk), .rst_n(rst_n),
    .rx(rx),
    .rx_tick(rx_tick),
    .done(done),
    .data_out(data_out)
  );

endmodule
