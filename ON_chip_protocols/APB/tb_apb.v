module tb_apb_top;

  reg clk;
  reg rst_n;
  reg transfer;
  reg read_write;
  reg [7:0] apb_write_data;
  reg [8:0] apb_write_addr;
  reg [8:0] apb_read_addr;

  wire [7:0] apb_read_data_out;

  /* DUT */
  apb_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .transfer(transfer),
    .read_write(read_write),
    .apb_write_data(apb_write_data),
    .apb_write_addr(apb_write_addr),
    .apb_read_addr(apb_read_addr),
    .apb_read_data_out(apb_read_data_out)
  );

  /* Clock */
  always #5 clk = ~clk;

  /* ---------------- WRITE TASK ---------------- */
  task write_apb(input [8:0] addr, input [7:0] data);
    begin
      @(posedge clk);
      transfer       = 1;
      read_write     = 0;
      apb_write_addr = addr;
      apb_write_data = data;

      // Wait for APB transaction to complete
      repeat(4) @(posedge clk);

      $display("[%0t] WRITE : Addr=%0d Data=%0d", $time, addr, data);

      transfer = 0;
    end
  endtask

  /* ---------------- READ TASK ---------------- */
  task read_apb(input [8:0] addr);
    begin
      @(posedge clk);
      transfer      = 1;
      read_write    = 1;
      apb_read_addr = addr;

      // Wait until read data becomes valid
      repeat(6) @(posedge clk);

      $display("[%0t] READ  : Addr=%0d Data=%0d",
               $time, addr, apb_read_data_out);

      transfer = 0;
    end
  endtask

  /* ---------------- TEST ---------------- */
  initial begin
    $dumpfile("apb.vcd");
    $dumpvars(0, tb_apb_top);

    $monitor("time = %0t | clk = %b ,rst_n = %b,transfer = %b,read_write = %b,apb_write_data = %b,apb_write_addr = %b,apb_read_addr = %b,apb_read_data_out = %b",$time,clk,rst_n,transfer,read_write,apb_write_data,apb_write_addr,apb_read_addr,apb_read_data_out);

    // Init
    clk = 0;
    rst_n = 0;
    transfer = 0;
    read_write = 0;
    apb_write_data = 0;
    apb_write_addr = 0;
    apb_read_addr  = 0;

    // Reset
    repeat(2) @(posedge clk);
    rst_n = 1;

    // Writes
    write_apb(9'd5,   8'd10);
    write_apb(9'd8,   8'd20);
    write_apb(9'd15, 8'd30);

    // Reads
    read_apb(9'd5);
    read_apb(9'd8);
    read_apb(9'd15);

    #20;
    $finish;
  end

endmodule
