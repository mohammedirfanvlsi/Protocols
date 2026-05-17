module tb_spi;

  // Testbench signals
  reg clk;
  reg rst_n;
  reg start;
  reg [7:0] master_tx_data;
  reg [7:0] slave_tx_data;

  wire [7:0] master_rx_data;
  wire [7:0] slave_rx_data;
  wire busy;

  // DUT instantiation (PORT NAMES MATCH EXACTLY)
  spi_top dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .start          (start),
    .master_tx_data (master_tx_data),
    .slave_tx_data  (slave_tx_data),
    .master_rx_data (master_rx_data),
    .slave_rx_data  (slave_rx_data),
    .busy           (busy)
  );

  // Clock generation
  always #5 clk = ~clk;

  // --------------------------------
  // SPI transfer task
  // --------------------------------
  task spi_transfer;
    input [7:0] m_tx;
    input [7:0] s_tx;
    begin
      master_tx_data = m_tx;
      slave_tx_data  = s_tx;

      @(posedge clk);
      start = 1;

      @(posedge clk);
      start = 0;

      // Wait for SPI to finish
      wait (busy == 0);
      #1;

      $display("[%0t] MASTER_TX=%h SLAVE_TX=%h | MASTER_RX=%h SLAVE_RX=%h",
                $time, m_tx, s_tx, master_rx_data, slave_rx_data);

      // Check
      if (master_rx_data !== s_tx)
        $display("❌ MASTER FAIL");
      else
        $display("✅ MASTER OK");

      if (slave_rx_data !== m_tx)
        $display("❌ SLAVE FAIL");
      else
        $display("✅ SLAVE OK");

      $display("----------------------------------");
    end
  endtask

  // --------------------------------
  // Test sequence
  // --------------------------------
  initial begin
    $dumpfile("spi.vcd");
    $dumpvars(0, tb_spi);

    $monitor("time = %0t | clk = %b,rst_n = %b,start = %b,master_tx_data = %b,slave_tx_data = %b,master_rx_data = %b,slave_rx_data = %b",$time,clk,rst_n,start,master_tx_data,slave_tx_data,master_rx_data,slave_rx_data);

    clk = 0;
    rst_n = 0;
    start = 0;
    master_tx_data = 0;
    slave_tx_data  = 0;

    #20 rst_n = 1;

    spi_transfer(8'hA5, 8'h3C);
    spi_transfer(8'h55, 8'hAA);
    spi_transfer(8'hF0, 8'h0F);

    #50;
    $finish;
  end

endmodule
