 module i2c_tb;

        // ==========================================
        // 2. Testbench Signals
        // ==========================================
        // In a testbench, any signal that WE (the virtual human) want to change
        // manually must be a 'reg' (register), because it has to hold its value.
        reg       clk;
        reg       rst_n;
        reg       m_start;
        reg [6:0] m_addr;
        reg       m_rw;
        reg [7:0] m_data_in;
        reg [7:0] s_data_in;

        // Any signal that comes OUT of our module must be a 'wire'.
        // We can't manually set these; we just look at them.
        wire [7:0] m_data_out;
        wire       m_busy;
        wire       m_ack_error;
        wire [7:0] s_data_out;
        wire       s_data_valid;

        // ==========================================
        // 3. Instantiating our Top Module
        // ==========================================
        // We bring in the top module (which contains our Master, Slave, and Pull-up resistors)
        // and connect our testbench wires to its ports.
        i2c_top uut (
            .clk          (clk),
            .rst_n        (rst_n),
            .m_start      (m_start),
            .m_addr       (m_addr),
            .m_rw         (m_rw),
            .m_data_in    (m_data_in),
            .m_data_out   (m_data_out),
            .m_busy       (m_busy),
            .m_ack_error  (m_ack_error),
            .s_data_in    (s_data_in),
            .s_data_out   (s_data_out),
            .s_data_valid (s_data_valid)
        );

        // ==========================================
        // 4. Clock Generation
        // ==========================================
        // We need a 50 MHz clock.
        // 50 MHz = 50,000,000 cycles per second.
        // 1 second / 50,000,000 = 20 nanoseconds (ns) per cycle.
        // So, every 10 ns, we flip the clock (10ns HIGH, 10ns LOW = 20ns total).
        always #10 clk = ~clk;

        // ==========================================
        // 5. The Main Simulation Block
        // ==========================================
        // 'initial' blocks run exactly once, starting at time 0.
        initial begin
            // --- STEP A: Initialize Everything ---
            clk       = 0;
            rst_n       = 0;     // Hold the reset button DOWN
            m_start   = 0;
            m_addr    = 0;
            m_rw      = 0;
            m_data_in = 0;



        s_data_in = 8'h88; // Give the slave some fake data to send later (Hex 88)

        // Wait for 100 nanoseconds, then release the reset button.
        #100;
        rst_n = 1;
        #100; // Wait a little more for things to settle.

        // ==========================================
        // --- STEP B: Master WRITES to Slave ---
        // ==========================================
        $display("--- STARTING WRITE TRANSACTION ---");

        // 1. Setup the Master's control inputs
        m_addr    = 7'h5A; // The exact address of our Slave
        m_rw      = 0;     // 0 means WRITE
        m_data_in = 8'hC3; // The data we want to send (Hex C3)

        // 2. Pulse the start button!
        m_start = 1;
        #3000;
        m_start = 0;

        // 3. Wait for the transaction to finish.
        // We use a 'wait' command to pause the testbench until the Master says it's no longer busy.
        // But since 'busy' takes a moment to turn on, we first wait for it to go HIGH, then wait for it to go LOW.
        wait(m_busy == 1);
        wait(m_busy == 0);

        // Let's add a small delay before the next transaction
        #1000;

        // Check if it worked! We print a message to the simulation console.
        if (s_data_out == 8'hC3)
            $display("SUCCESS! Slave successfully received: %h", s_data_out);
        else
            $display("ERROR! Slave received: %h", s_data_out);


        // ==========================================
        // --- STEP C: Master READS from Slave ---
        // ==========================================
        $display("--- STARTING READ TRANSACTION ---");

        // 1. Setup the Master's control inputs
        m_addr    = 7'h5A; // Same slave address
        m_rw      = 1;     // 1 means READ
        // We don't care about m_data_in because we are reading, not writing.

        // 2. Pulse the start button!
        m_start = 1;
        #3000;
        m_start = 0;

        // 3. Wait for the transaction to finish.
        wait(m_busy == 1);
        wait(m_busy == 0);

        #1000;

        // Check if the Master successfully grabbed the '8'h88' data we loaded into the Slave earlier!
        if (m_data_out == 8'h88)
            $display("SUCCESS! Master successfully read: %h", m_data_out);
        else
            $display("ERROR! Master read: %h", m_data_out);

        // ==========================================
        // --- STEP D: Finish Simulation ---
        // ==========================================
        // $finish stops the simulation entirely. If you don't include this,
        // the clock will just keep ticking forever!
        $display("--- SIMULATION COMPLETE ---");
        $finish;
    end

  endmodule