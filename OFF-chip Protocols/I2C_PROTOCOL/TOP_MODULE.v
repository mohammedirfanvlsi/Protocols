  module i2c_top (
        // 1. System Signals
        input  wire       clk,          // Main 50 MHz clock
        input  wire       rst_n,        // System reset

        // 2. Master Control Interface (How we tell the master what to do)
        input  wire       m_start,      // Pulse 1 to tell Master to start
        input  wire [6:0] m_addr,       // Address the Master wants to talk to
        input  wire       m_rw,         // 0 = Write to Slave, 1 = Read from Slave
        input  wire [7:0] m_data_in,    // Data Master wants to send
        output wire [7:0] m_data_out,   // Data Master received
        output wire       m_busy,       // Is Master currently busy?
        output wire       m_ack_error,  // Did the Slave fail to respond?

        // 3. Slave Control Interface (How we see what the slave is doing)
        input  wire [7:0] s_data_in,    // Data Slave will send if Master reads from it
        output wire [7:0] s_data_out,   // Data Slave received from Master
        output wire       s_data_valid  // Pulses 1 when Slave receives a new byte
    );

        // ==========================================
        // The Physical I2C Bus Wires
        // ==========================================
        // These are the two shared wires that connect both devices.
        wire sda;
        wire scl;

        // *** THE SECRET SAUCE ***
        // Because I2C uses Open-Drain logic (1'bz), we MUST simulate the physical
        // pull-up resistors that exist on a real circuit board.
        // If nobody is pulling SDA or SCL to 0, these 'pullup' commands will gently
        // force the wires to 1.
        pullup(sda);
        pullup(scl);


        // ==========================================
        // Instantiating the Master
        // ==========================================
        // We drop the i2c_master onto our "breadboard" and name it 'u_master'.
        i2c_master u_master (
            .clk        (clk),
            .rst_n      (rst_n),
            .start      (m_start),
            .addr       (m_addr),
            .rw         (m_rw),
            .data_in    (m_data_in),
            .data_out   (m_data_out),
            .busy       (m_busy),
            .ack_error  (m_ack_error),

            // Connect the Master's physical pins to our shared bus wires!
            .sda        (sda),
            .scl        (scl)
        );


        // ==========================================
        // Instantiating the Slave
        // ==========================================
        // We drop the i2c_slave onto our "breadboard" and name it 'u_slave'.
        // We also set its parameter MY_ADDR to 7'h5A so it knows its own name.
        i2c_slave #(
            .MY_ADDR    (7'h5A)
        ) u_slave (
            .clk        (clk),
            .rst_n      (rst_n),

            // Connect the Slave's physical pins to the exact same shared bus wires!
            .sda        (sda),
            .scl        (scl),

            .data_out   (s_data_out),
            .data_valid (s_data_valid),
            .data_in    (s_data_in)
        );

    endmodule
