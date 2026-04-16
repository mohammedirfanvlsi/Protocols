module uart_tb;

  // parameters
  parameter SYS_CLK   = 50_000_000;
  parameter BAUD_RATE = 9600;

  // signals
  reg clk;
  reg rst;
  reg tx_en;
  reg [7:0] data_in;

  wire tx;
  wire rx;
  wire busy;
  wire done;
  wire [7:0] data_out;

  // DUT
  uart_top #(
    .sys_clk(SYS_CLK),
    .baud_rate(BAUD_RATE)
  ) dut (
    .clk(clk),
    .rst(rst),
    .tx_en(tx_en),
    .data_in(data_in),
    .rx(rx),
    .tx(tx),
    .busy(busy),
    .done(done),
    .data_out(data_out)
  );

  // loopback connection
  assign rx = tx;

  // clock generation → 50 MHz
  always #10 clk = ~clk;

initial begin

    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);

    // monitor (same style as yours)
    $monitor("time=%0t | tx_en=%b | busy=%b | tx=%b | rx=%b | done=%b | data_out=%b",
      $time, tx_en, busy, tx, rx, done, data_out);
end


  initial begin
    // init
    clk     = 0;
    rst     = 0;
    tx_en  = 0;
    data_in = 8'd0;

    // reset
    repeat(5) @(posedge clk);
    rst = 1;

    // wait little
    repeat(5) @(posedge clk);

    // -------------------------
    // SEND DATA
    // -------------------------
    send_byte(8'h55);
    send_byte(8'hA3);
    send_byte(8'h0F);

    #1000000;
    $finish;
  end

  // -------------------------
  // TASK : SEND ONE BYTE
  // -------------------------
 task send_byte(input [7:0] data);
  begin
    @(posedge clk);
    data_in = data;
    tx_en = 1;

    // HOLD tx_en until TX accepts it
    wait (busy == 1);

    @(posedge clk);
    tx_en = 0;

    // wait for TX to finish
    wait (busy == 0);

    // wait RX done
    wait (done == 1);

    if (data_out == data)
      $display("✔ SUCCESS: Sent %h Received %b", data, data_out);
    else
      $display("✘ ERROR: Sent %h Received %b", data, data_out);
  end
endtask
endmodule
