module apb_protocol (
    input clk,            // Main system clock
    input rst_n,          // Active-low reset
    input pready,         // Signal from Slave: "I am ready / I have finished the transfer"
    input transfer,       // User signal to tell Master: "Start a new APB transfer!"
    input read_write,     // User signal: 1 = Read from Slave, 0 = Write to Slave
    input [31:0] apb_write_data, // The data the user wants to write to the Slave
    input [31:0] prdata,   // The data the Master reads from the APB bus (from Slave)
    input [31:0] apb_read_addr,  // The address the user wants to read from
    input [31:0] apb_write_addr, // The address the user wants to write to
    output reg sel1,      // Chip Select for Slave 1 (PSEL1)
    output reg sel2,      // Chip Select for Slave 2 (PSEL2)
    output reg pwrite,    // APB Write/Read control signal (1 = Write, 0 = Read)
    output reg penable,   // APB Enable signal (triggers the actual transfer in Access Phase)
    output reg [31:0] pwdata, // APB Write Data bus (data going to the Slave)
    output reg [31:0] apb_read_data_out, // Data given back to the user after a successful read
    output reg [31:0] paddr   // APB Address bus
);

    // State Machine Encodings for the 3 APB States
    localparam idle   = 2'b00; // IDLE: Bus is resting, nothing is happening
    localparam setup  = 2'b01; // SETUP: PSEL is high, address/data is placed on bus. PENABLE is 0.
    localparam access = 2'b10; // ACCESS: PENABLE goes high. Waiting for Slave to say PREADY.
    
    reg [1:0] state, next_state; // Current state and Next state registers

    // Sequential Block: Updates the current state on every clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // On reset, go to IDLE and clear the user output data
            state <= idle;
            apb_read_data_out <= 0;
        end else begin
            // Advance to the next state determined by the combinational block
            state <= next_state;

            // If we are in the ACCESS phase AND the Slave is ready AND it was a Read operation...
            if (state == access && pready && read_write) begin
                // Capture the data coming from the Slave (PRDATA) and give it to the user
                apb_read_data_out <= prdata;
            end
        end
    end

    // Combinational Block: Determines next_state and APB output signals based on current state
    always @(*) begin
        // DEFAULT VALUES: Prevent latches by assigning defaults to all outputs first!
        penable = 0;
        sel1 = 0;
        sel2 = 0;
        pwdata = 0;
        paddr = 0;
        pwrite = 0;
        next_state = state; // Default next state is to stay in the current state

        case(state) 
            idle: begin
                // In IDLE, if the user requests a transfer, move to the SETUP phase
                if (transfer)
                    next_state = setup;
                else 
                    next_state = idle; // Otherwise, stay in IDLE
            end

            setup: begin
                // APB SETUP PHASE: PENABLE must be 0!
                penable = 0;
                
                // Note: user input read_write is (1=Read, 0=Write). 
                // But APB PWRITE standard is (1=Write, 0=Read). 
                // So we invert it using ~read_write.
                pwrite = ~read_write;

                // Put the correct address and data on the bus depending on if it's a read or write
                if (read_write) begin // Read operation
                    paddr = apb_read_addr;
                    pwdata = 0; // Don't care about write data during a read
                end else begin // Write operation
                    paddr = apb_write_addr;
                    pwdata = apb_write_data;
                end

                // Address Decoding: Decide which slave to talk to!
                // We use the top bit (bit 31) of the address to choose.
                // If bit 31 is 0, talk to Slave 1. If bit 31 is 1, talk to Slave 2.
                if (paddr[31] == 1'b0) begin
                    sel1 = 1; // Assert PSEL1
                    sel2 = 0;
                end else begin
                    sel1 = 0;
                    sel2 = 1; // Assert PSEL2
                end

                // The SETUP phase always lasts exactly 1 clock cycle, so unconditionally go to ACCESS
                next_state = access;
            end

            access: begin
                // APB ACCESS PHASE: PENABLE goes to 1! This triggers the read/write.
                penable = 1;
                pwrite = ~read_write;

                // We must HOLD all the exact same address and data values from the SETUP phase
                if (read_write) begin
                    paddr = apb_read_addr;
                    pwdata = 0;
                end else begin
                    paddr = apb_write_addr;
                    pwdata = apb_write_data;
                end

                // We must HOLD the exact same Chip Select (PSEL) values from the SETUP phase
                if (paddr[31] == 1'b0) begin
                    sel1 = 1;
                    sel2 = 0;
                end else begin
                    sel1 = 0;
                    sel2 = 1;
                end

                // Check if the Slave has finished the job
                if (pready) begin
                    // Slave is done! Do we have another transfer waiting immediately?
                    if (transfer)
                        next_state = setup; // Back-to-back transfer (go straight to setup)
                    else 
                        next_state = idle;  // No more transfers, rest in IDLE
                end else begin
                    // Slave is NOT ready (PREADY=0). This is called a WAIT STATE.
                    // We must stay in the ACCESS phase holding all signals steady until Slave is ready.
                    next_state = access;
                end
            end

            default: next_state = idle; // Safe fallback state
        endcase
    end
endmodule
