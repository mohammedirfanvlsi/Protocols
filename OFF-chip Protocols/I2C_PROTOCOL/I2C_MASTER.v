module i2c_master (
    input  wire       clk,       // Main system clock (50 MHz) - High speed clock used for internal logic
    input  wire       rst_n,     // Active-low reset button - '0' resets the system
    input  wire       start,     // Pulse 1 to begin communication - acts as a trigger to start I2C transaction
    input  wire [6:0] addr,      // 7-bit slave address - tells the master WHICH slave to talk to
    input  wire       rw,        // 0 = Write to slave, 1 = Read from slave
    input  wire [7:0] data_in,   // Data byte the master wants to send to the slave
    output reg  [7:0] data_out,  // Data byte the master reads from the slave
    output reg        busy,      // 1 = I2C is running, 0 = idle. Used to tell outside world "I am working"
    output reg        ack_error, // 1 = Slave did not respond with an ACK (error condition)
    inout  wire       sda,       // Physical Data wire - bidrectional (inout)
    inout  wire       scl        // Physical Clock wire - bidrectional (inout)
);

    // To get 100kHz I2C clock from a 50MHz system clock, we need a 400kHz internal tick.
    // 50,000,000 / 400,000 = 125. So we count 0 to 124.
    parameter CLK_DIV = 125;
    reg [7:0] clk_count; // Counter register to divide the clock
    reg       i2c_tick;  // This pulses 1 exactly 400,000 times a second (4 phases * 100kHz)

    // Clock divider logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // If reset is pressed
            clk_count <= 0; // Reset counter
            i2c_tick  <= 0; // Reset tick
        end else begin
            if (clk_count == CLK_DIV - 1) begin // If we reached 124
                clk_count <= 0; // Reset counter back to 0
                i2c_tick  <= 1; // Generate one pulse of the 400kHz tick
            end else begin
                clk_count <= clk_count + 1; // Increment counter
                i2c_tick  <= 0; // Keep tick low
            end
        end
    end

    // Internal registers to hold what we WANT to output on SDA and SCL
    reg sda_out; 
    reg scl_out; 

    // OPEN-DRAIN LOGIC (Crucial for I2C)
    // If we want to output 0, we pull the wire down (1'b0).
    // If we want to output 1, we "let go" (1'bz - high impedance) and let the pull-up resistor pull it high.
    assign sda = (sda_out == 1'b0) ? 1'b0 : 1'bz;
    assign scl = (scl_out == 1'b0) ? 1'b0 : 1'bz;

    // State Machine States
    localparam IDLE      = 3'd0; // Waiting for start signal
    localparam START     = 3'd1; // Generating I2C Start Condition
    localparam SEND_ADDR = 3'd2; // Sending 7-bit address + 1-bit R/W
    localparam ACK_ADDR  = 3'd3; // Waiting for slave to acknowledge address
    localparam SEND_DATA = 3'd4; // Sending 8-bit data
    localparam RECV_DATA = 3'd5; // Receiving 8-bit data
    localparam ACK_DATA  = 3'd6; // Sending/Receiving data acknowledge
    localparam STOP      = 3'd7; // Generating I2C Stop Condition

    reg [2:0] state;     // Current state of the state machine
    reg [1:0] phase;     // Phase counter (0, 1, 2, 3) for the 4 phases of SCL
    reg [3:0] bit_count; // Counts how many bits we have sent/received (0 to 7)
    reg [7:0] shift_reg; // Holds the 8 bits being shifted in or out

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // Reset all registers to default safe values
            state     <= IDLE;
            busy      <= 0;
            ack_error <= 0;
            sda_out   <= 1; // 1 means "let go" of SDA
            scl_out   <= 1; // 1 means "let go" of SCL
            phase     <= 0;
            bit_count <= 0;
        end else if (i2c_tick) begin // Only change state 400,000 times a second (4x per I2C clock cycle)
            case (state)
                IDLE: begin
                    sda_out <= 1; // Bus is idle, both wires high
                    scl_out <= 1; 

                    if (start) begin // Someone told us to start!
                        busy      <= 1; // Mark ourselves as busy
                        ack_error <= 0; // Clear any previous errors
                        // Combine 7-bit addr and 1-bit R/W into one 8-bit byte to send
                        shift_reg <= (addr << 1) | rw; 
                        state     <= START; // Go to START state
                        phase     <= 0; // Reset phase
                    end
                end

                START: begin
                    // I2C Start Condition: SDA goes LOW while SCL is HIGH
                    case (phase)
                        0: begin
                               sda_out <= 1; // Keep both high initially
                               scl_out <= 1;
                           end
                        1: begin
                               sda_out <= 0; // SDA falls! This is the START condition
                               scl_out <= 1; // SCL stays high
                           end
                        2: begin
                               sda_out <= 0; // Hold SDA low
                               scl_out <= 1; // Keep SCL high
                           end
                        3: begin
                               sda_out <= 0; // Keep SDA low
                               scl_out <= 0; // SCL goes low, ready to send data bits

                               state     <= SEND_ADDR; // Move to sending address
                               bit_count <= 0; // Reset bit counter
                           end
                    endcase
                    phase <= phase + 1; // Move to next phase
                end

                SEND_ADDR: begin
                    case (phase)
                        0: begin
                               sda_out <= shift_reg[7]; // Put the Most Significant Bit on SDA
                               scl_out <= 0; // Keep SCL low so data can safely change
                           end
                        1: begin
                               scl_out <= 1; // Raise SCL (Slave will read the bit now)
                           end
                        2: begin
                               scl_out <= 1; // Keep SCL high to ensure stable read by slave
                           end
                        3: begin
                               scl_out <= 0; // Lower SCL so we can change data again next phase

                               shift_reg <= shift_reg << 1; // Shift left to get the next bit ready
                               bit_count <= bit_count + 1; // We sent 1 bit
                               if (bit_count == 7) state <= ACK_ADDR; // If we sent 8 bits, go wait for ACK
                           end
                    endcase
                    phase <= phase + 1;
                end

                ACK_ADDR: begin // 9th clock pulse: Waiting for slave to pull SDA low
                    case (phase)
                        0: begin
                               sda_out <= 1; // Master MUST let go of SDA (output 1) so slave can pull it down
                               scl_out <= 0; // SCL is low, slave can change SDA
                           end
                        1: begin
                               scl_out <= 1; // Raise SCL
                           end
                        2: begin
                               ack_error <= sda; // Read SDA. If slave pulled it down, sda is 0 (No error). If 1, error!
                           end
                        3: begin
                               scl_out <= 0; // Lower SCL

                               bit_count <= 0; // Reset bit counter for data phase
                               if (ack_error) begin // If no slave responded
                                   state <= STOP; // Abort and STOP
                               end else if (rw == 0) begin // If we are writing
                                   state     <= SEND_DATA;
                                   shift_reg <= data_in; // Load the data we want to write
                               end else begin // If we are reading
                                   state     <= RECV_DATA;
                               end
                           end
                    endcase
                    phase <= phase + 1;
                end

                SEND_DATA: begin
                    // Exact same logic as SEND_ADDR, but sending data instead
                    case (phase)
                        0: begin
                               sda_out <= shift_reg[7]; // Send MSB
                               scl_out <= 0;
                           end
                        1: begin
                               scl_out <= 1; // Raise SCL
                           end
                        2: begin
                               scl_out <= 1; // Hold SCL
                           end
                        3: begin
                               scl_out <= 0; // Lower SCL

                               shift_reg <= shift_reg << 1; // Shift to next bit
                               bit_count <= bit_count + 1;
                               if (bit_count == 7) state <= ACK_DATA; // After 8 bits, wait for ACK
                           end
                    endcase
                    phase <= phase + 1;
                end

                RECV_DATA: begin
                    // Master is receiving data from the Slave
                    case (phase)
                        0: begin
                               sda_out <= 1; // Master MUST let go of SDA so slave can drive it
                               scl_out <= 0; // SCL low
                           end
                        1: begin
                               scl_out <= 1; // Raise SCL
                           end
                        2: begin
                               // Read the bit on SDA and shift it into our register
                               shift_reg <= (shift_reg << 1) | sda; 
                           end
                        3: begin
                               scl_out <= 0; // Lower SCL

                               bit_count <= bit_count + 1;
                               if (bit_count == 7) state <= ACK_DATA; // After 8 bits, go to ACK
                           end
                    endcase
                    phase <= phase + 1;
                end

                ACK_DATA: begin
                    case (phase)
                        0: begin
                               scl_out <= 0;
                               if (rw == 0) // If we were writing, Master lets go (outputs 1) so Slave can ACK
                                   sda_out <= 1; 
                               else         // If we were reading, Master must send NACK (1) or ACK (0) here. 
                                   sda_out <= 1; // Currently hardcoded to NACK after 1 byte.
                           end
                        1: begin
                               scl_out <= 1; // Raise SCL
                           end
                        2: begin
                               if (rw == 0) ack_error <= sda; // Check if slave ACKed our write
                           end
                        3: begin
                               scl_out <= 0; // Lower SCL

                               if (rw == 1) data_out <= shift_reg; // If we were reading, save the received data
                               state <= STOP; // We only support 1 byte transfers right now, so go to STOP
                           end
                    endcase
                    phase <= phase + 1;
                end

                STOP: begin
                    // I2C Stop Condition: SDA goes HIGH while SCL is HIGH
                    case (phase)
                        0: begin
                               sda_out <= 0; // Make sure SDA is low first
                               scl_out <= 0; 
                           end
                        1: begin
                               sda_out <= 0; 
                               scl_out <= 1; // Raise SCL first
                           end
                        2: begin
                               sda_out <= 1; // SDA rises while SCL is high! This is the STOP condition.
                               scl_out <= 1; 
                           end
                        3: begin
                               state <= IDLE; // Go back to idle
                               busy  <= 0;    // We are done!
                           end
                    endcase
                    phase <= phase + 1;
                end
            endcase
        end
    end
endmodule
