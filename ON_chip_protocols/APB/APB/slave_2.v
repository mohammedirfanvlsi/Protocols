module apb_slave_2(input clk ,rst_n,penable,psel,pwrite,
                   input [31:0]paddr,
                   input[31:0]pwdata,
                   output[31:0]prdata2,
                   output reg  pready2 );

reg[31:0] reg_addr;
reg[31:0]mem[0:255];

assign prdata2 = mem[paddr[7:0]];

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        pready2 <= 0;
    else if (psel && penable && !pwrite)begin
        pready2 <= 1;
        reg_addr <= paddr;
    end
    else if (psel && penable && pwrite)begin
        pready2 <= 1;
        mem[paddr[7:0]] <= pwdata;
    end
    else 
        pready2 <= 0;
end
endmodule
