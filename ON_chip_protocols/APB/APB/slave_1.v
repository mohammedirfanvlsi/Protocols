module apb_slave_1 (
    input clk,       // Main system clock
    input rst_n,     // Active-low reset
    input penable,   // APB Enable signal (Trigger for the Access phase)
    input psel,      // APB Select signal (Tells this slave "The Master is talking to YOU")
    input pwrite,    // APB Write control (1 = Write, 0 = Read)
    input [31:0] paddr, // APB Address bus (Which memory slot to read/write)
    input [31:0] pwdata, // APB Write Data bus (Data coming from Master)
    output [31:0] prdata1, // APB Read Data bus (Data going back to Master)
    output reg pready1    // APB Ready signal (Tells Master "I am done!")
);

    // Internal memory array to act as the slave's storage
    // It has 256 slots (0 to 255), and each slot holds 32 bits.
    reg [31:0] mem [0:255]; 
    
    // We use this to briefly remember the address we want to read
    reg [31:0] reg_addr;

    // READ LOGIC: Combinational read from memory
    assign prdata1 = mem[paddr[7:0]];

    // WRITE LOGIC & PREADY LOGIC (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pready1 <= 0;
        end 
        else if (psel && penable && !pwrite) begin
            pready1 <= 1; 
            reg_addr <= paddr; 
        end 
        else if (psel && penable && pwrite) begin
            pready1 <= 1; 
            mem[paddr[7:0]] <= pwdata;
        end 
        else begin
            pready1 <= 0;
        end
    end
endmodule
