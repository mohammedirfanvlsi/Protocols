module uart_top #(
  parameter sys_clk = 50_000_000,
  parameter baud_rate = 9600
)(
  input clk,
  input rst,
  input tx_en,
  input [7:0] data_in,
  input rx,
  output tx,
  output busy,
  output done,
  output [7:0] data_out
);

  wire tx_tick, rx_tick;

  tx_baud_generator #(.sys_clk(sys_clk), .baud_rate(baud_rate))
  TX_BAUD (.clk(clk), .rst(rst), .baud_en(1'b1), .tx_tick(tx_tick));

  rx_baud_generator #(.sys_clk(sys_clk), .baud_rate(baud_rate))
  RX_BAUD (.clk(clk), .rst(rst), .baud_en(1'b1), .rx_tick(rx_tick));

  transmitter TX (
    .clk(clk), .rst(rst),
    .tx_en(tx_en),
    .tx_tick(tx_tick),
    .data_in(data_in),
    .tx(tx),
    .busy(busy)
  );

  receiver RX (
    .clk(clk), .rst(rst),
    .rx(rx),
    .rx_tick(rx_tick),
    .done(done),
    .data_out(data_out)
  );

endmodule
