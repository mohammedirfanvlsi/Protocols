module tb_apb_top;

  reg clk;
  reg rst_n;
  reg transfer;
  reg read_write;
  reg [31:0] apb_write_data;
  reg [31:0] apb_write_addr;
  reg [31:0] apb_read_addr;

  wire [31:0] apb_read_data_out;

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
  task write_apb(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      transfer       = 1;
      read_write     = 0;
      apb_write_addr = addr;
      apb_write_data = data;

      repeat(4) @(posedge clk);

      $display("[%0t] WRITE : Addr=%h Data=%d", $time, addr, data);

      transfer = 0;
    end
  endtask

  /* ---------------- READ TASK ---------------- */
  task read_apb(input [31:0] addr);
    begin
      @(posedge clk);
      transfer      = 1;
      read_write    = 1;
      apb_read_addr = addr;

      repeat(6) @(posedge clk);

      $display("[%0t] READ  : Addr=%h Data=%d",
               $time, addr, apb_read_data_out);

      transfer = 0;
    end
  endtask

  /* ---------------- TEST ---------------- */
  initial begin
    $dumpfile("apb.vcd");
    $dumpvars(0, tb_apb_top);

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

    // Writes to Slave 1 (Bit 31 is 0)
    write_apb(32'h0000_0005, 32'd100000);
    write_apb(32'h0000_0008, 32'd200000);
    
    // Writes to Slave 2 (Bit 31 is 1)
    write_apb(32'h8000_0005, 32'd300000);
    write_apb(32'h8000_0008, 32'd400000);

    // Reads from Slave 1
    read_apb(32'h0000_0005);
    read_apb(32'h0000_0008);
    
    // Reads from Slave 2
    read_apb(32'h8000_0005);
    read_apb(32'h8000_0008);

    #20;
    $finish;
  end

endmodule
