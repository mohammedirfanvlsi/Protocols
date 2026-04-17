module uart_tb;

 parameter tx_sys_clk = 10_000_000;
  parameter rx_sys_clk = 40_000_000;
  parameter baud_rate = 9600;
  parameter data_width = 8;
  
  reg tx_clk,rx_clk;
  reg rst_n;
  reg tx_en;
  reg [7:0] data_in;

  wire tx;
  wire rx;
  wire busy;
  wire done;
  wire [7:0] data_out;

  
  uart_top #(
    .tx_sys_clk(tx_sys_clk),
    .rx_sys_clk(rx_sys_clk),
    .baud_rate(baud_rate),
    .data_width(data_width)
  ) dut (
    .tx_clk(tx_clk),.rx_clk(rx_clk),
    .rst_n(rst_n),
    .tx_en(tx_en),
    .data_in(data_in),
    .rx(rx),
    .tx(tx),
    .busy(busy),
    .done(done),
    .data_out(data_out)
  );

  
  assign rx = tx;

  
  always #50 tx_clk = ~tx_clk;
  always #12.5 rx_clk = ~rx_clk;

initial begin

    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);

   
    $monitor("time=%0t | tx_en=%b | busy=%b | tx=%b | rx=%b | done=%b | data_out=%b",
      $time, tx_en, busy, tx, rx, done, data_out);
end


  initial begin
   
    tx_clk = 0;
    rx_clk = 0;
    rst_n = 0;
    tx_en = 0;
    data_in = 8'd0;

    
    
    #100 rst_n =1;
    


    repeat(5) @(posedge tx_clk);

    send_byte(8'h55);
    send_byte(8'hA3);
    send_byte(8'h0F);

    #1000000;
    $finish;
  end

 
  // TASK
  
 task send_byte(input [7:0] data);
  begin
    @(posedge tx_clk);
    data_in = data;
    tx_en = 1;

    // HOLD tx_en until TX accepts it
    wait (busy == 1);

    @(posedge tx_clk);
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
