module apb_slave_1(input clk ,rst_n,penable,psel,pwrite,
                   input [8:0]paddr,
                   input[7:0]pwdata,
                   output[7:0]prdata1,
                   output reg pready1 );

  
reg[7:0] reg_addr;
reg[7:0]mem[0:255];

assign prdata1 = mem[paddr[7:0]];

always @(posedge clk or negedge rst_n)begin

    if(!rst_n)

        pready1 <= 0;

    else if (psel && penable && !pwrite)begin

        pready1 <= 1;
        reg_addr <= paddr[7:0];

    end

    else if (psel && penable && pwrite)begin

        pready1 <= 1;
        mem[paddr[7:0]] <= pwdata;

    end

    else 

        pready1 <= 0;

end

endmodule





        
