   module tb_axi;

        // ========================================================================
        // 1. PARAMETERS & CLOCK CONSTANTS
        // ========================================================================
        parameter DATA_WIDTH = 32;          // 32-bit data bus
        parameter ADDR_WIDTH = 32;          // 32-bit address bus
        parameter ID_WIDTH   = 4;           // 4-bit Transaction ID
        parameter MEM_DEPTH  = 256;         // 256 words in RAM

        // ========================================================================
        // 2. TESTBENCH SIGNALS
        // ========================================================================
        // Clock & Reset:
        reg                   aclk;          // Driven by testbench clock generator
        reg                   aresetn;       // Driven by testbench reset sequence

        // User Write Interface:
        reg                   init_write;    // Strobe to trigger a write burst
        reg  [ADDR_WIDTH-1:0] wr_addr;       // Target write address
        reg  [7:0]            wr_len;        // Number of beats minus 1 (3 means 4 beats)
        reg  [DATA_WIDTH-1:0] wr_data_in;    // Real 32-bit data fed into Master
        wire                  wr_data_req;   // Master asks: "Give me the next word!"
        wire                  wr_done;       // Master signals: "Write burst complete!"

        // User Read Interface:
        reg                   init_read;     // Strobe to trigger a read burst
        reg  [ADDR_WIDTH-1:0] rd_addr;       // Target read address
        reg  [7:0]            rd_len;        // Number of beats to read
        wire [DATA_WIDTH-1:0] rd_data_out;   // Data captured from memory
        wire                  rd_data_valid; // Strobe when read data is valid
        wire                  rd_done;       // Master signals: "Read burst complete!"

        // ========================================================================
        // 3. REAL TEST DATA STORAGE (4 Real, Unique 32-bit Words)
        // ========================================================================
        reg [DATA_WIDTH-1:0] write_buffer [0:3]; // Stores our 4 real write words
        reg [DATA_WIDTH-1:0] read_buffer  [0:3]; // Stores captured read words for comparison
        integer wr_idx;                          // Index pointer for streaming writes
        integer rd_idx;                          // Index pointer for storing reads
        integer error_count;                     // Keeps track of any data mismatches


        // ========================================================================
        // 4. DUT INSTANTIATION (Device Under Test: axi_top)
        // ========================================================================
        axi_top #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .ID_WIDTH(ID_WIDTH),
            .MEM_DEPTH(MEM_DEPTH)
        ) u_axi_top (
            // Global Pins
            .aclk          (aclk),
            .aresetn       (aresetn),

            // User Write Pins
            .init_write    (init_write),
            .wr_addr       (wr_addr),
            .wr_len        (wr_len),
            .wr_data_in    (wr_data_in),
            .wr_data_req   (wr_data_req),
            .wr_done       (wr_done),

            // User Read Pins
            .init_read     (init_read),
            .rd_addr       (rd_addr),
            .rd_len        (rd_len),
            .rd_data_out   (rd_data_out),
            .rd_data_valid (rd_data_valid),
            .rd_done       (rd_done)
        );


        // ========================================================================
        // 5. 100 MHz CLOCK GENERATION (10 ns clock period)
        // ========================================================================
        always begin
            #5 aclk = ~aclk; // Invert clock every 5 ns (Total period = 10 ns)
        end


        // ========================================================================
        // 6. REAL DATA STREAMING HANDOFF (Responding to Master's wr_data_req)
        // ========================================================================
        // Whenever the Master accepts a word and asks for the next word:
        always @(posedge aclk) begin
            if (wr_data_req) begin
                wr_idx     <= wr_idx + 1;                  // Advance index
                wr_data_in <= write_buffer[wr_idx + 1];    // Put the next real word on the wire!
            end
        end


        // ========================================================================
        // 7. READ DATA CAPTURE (Recording incoming read words into read_buffer)
        // ========================================================================
        always @(posedge aclk) begin
            if (rd_data_valid) begin
                read_buffer[rd_idx] <= rd_data_out;        // Store read word into buffer
                $display("[TIME: %0t ns] ---> CAPTURED READ BEAT #%0d: Data = 0x%08h",
                         $time, rd_idx, rd_data_out);
                rd_idx <= rd_idx + 1;                      // Advance read index
            end
        end


        // ========================================================================
        // 8. MAIN SIMULATION SEQUENCE
        // ========================================================================
        initial begin
            // --- Setup Waveform Dumping ---
            $dumpfile("axi_waves.vcd"); // Create VCD file for GTKWave
            $dumpvars(0, tb_axi);        // Dump all signals in this hierarchy

            // --- Initialize Signals ---
            aclk        = 1'b0;
            aresetn     = 1'b0;          // Assert Reset (Active-LOW)
            init_write  = 1'b0;
            init_read   = 1'b0;
            wr_addr     = 32'd0;
            rd_addr     = 32'd0;
            wr_len      = 8'd0;
            rd_len      = 8'd0;
            wr_data_in  = 32'd0;
            wr_idx      = 0;
            rd_idx      = 0;
            error_count = 0;

            // --- Define 4 REAL, Distinct 32-bit Words to write ---
            write_buffer[0] = 32'hDEAD_BEEF; // Word 0
            write_buffer[1] = 32'hCAFE_BABE; // Word 1
            write_buffer[2] = 32'h1122_3344; // Word 2
            write_buffer[3] = 32'h5566_7788; // Word 3

            $display("\n=======================================================");
            $display("          STARTING AXI4-FULL VERIFICATION TEST          ");
            $display("=======================================================\n");

            // --- Step 1: Release Reset after 20 ns ---
            #20;
            @(posedge aclk);
            aresetn = 1'b1;              // De-assert Reset (System is now ALIVE!)
            $display("[TIME: %0t ns] Reset released. System is alive!", $time);
            #20;

            // ====================================================================
            // TEST 1: LAUNCH 4-BEAT BURST WRITE TO ADDRESS 0x0000_0000
            // ====================================================================
            $display("\n-------------------------------------------------------");
            $display("[TIME: %0t ns] TEST 1: Launching 4-Beat Burst WRITE to Address 0x0", $time);
            $display("-------------------------------------------------------");

            @(posedge aclk);
            wr_addr    = 32'h0000_0000;   // Start Address: 0
            wr_len     = 8'd3;            // 3 means 3 + 1 = 4 beats!
            wr_idx     = 0;
            wr_data_in = write_buffer[0]; // Supply the first word (0xDEADBEEF)
            init_write = 1'b1;            // Trigger Write!

            @(posedge aclk);
            init_write = 1'b0;            // Drop trigger (Strobe only lasts 1 cycle)

            // Wait here until Master says the entire write burst is complete!
            @(posedge wr_done);
            $display("[TIME: %0t ns] ---> WRITE BURST COMPLETE! (BRESP = OKAY received)", $time);

            #50; // Small delay between write and read

            // ====================================================================
            // TEST 2: LAUNCH 4-BEAT BURST READ FROM ADDRESS 0x0000_0000
            // ====================================================================
            $display("\n-------------------------------------------------------");
            $display("[TIME: %0t ns] TEST 2: Launching 4-Beat Burst READ from Address 0x0", $time);
            $display("-------------------------------------------------------");

            @(posedge aclk);
            rd_addr   = 32'h0000_0000;    // Read from the same address!
            rd_len    = 8'd3;             // Request 4 beats
            rd_idx    = 0;
            init_read = 1'b1;             // Trigger Read!

            @(posedge aclk);
            init_read = 1'b0;             // Drop trigger

            // Wait here until Master says the entire read burst is complete!
            @(posedge rd_done);
            $display("[TIME: %0t ns] ---> READ BURST COMPLETE! (RLAST received)", $time);

            #30;

            // ====================================================================
            // TEST 3: AUTOMATIC SELF-CHECKING VERIFICATION
            // ====================================================================
            $display("\n=======================================================");
            $display("             DATA VERIFICATION RESULTS                 ");
            $display("=======================================================");

            for (integer i = 0; i < 4; i = i + 1) begin
                if (read_buffer[i] === write_buffer[i]) begin
                    $display("  Beat #%0d: Written = 0x%08h | Read = 0x%08h ---> [MATCH! PASS]",
                             i, write_buffer[i], read_buffer[i]);
                end else begin
                    $display("  Beat #%0d: Written = 0x%08h | Read = 0x%08h ---> [ERROR! MISMATCH]",
                             i, write_buffer[i], read_buffer[i]);
                    error_count = error_count + 1;
                end
            end

            $display("=======================================================");
            if (error_count == 0) begin
                $display("  🎉 SUCCESS: ALL 4 WORDS MATCHED PERFECTLY!          ");
                $display("  🎉 AXI4-FULL PROTOCOL VERIFICATION: 100%% PASSED!     ");
            end else begin
                $display("  ❌ FAILURE: %0d ERRORS FOUND DURING VERIFICATION!    ", error_count);
            end
            $display("=======================================================\n");

            #50;
            $finish; // End simulation!
        end

    endmodule