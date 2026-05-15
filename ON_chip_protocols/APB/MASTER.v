module apb_protocol (input clk,rst_n,pready,transfer,read_write, 
                     input [7:0] apb_write_data,prdata,
                     input [8:0]apb_read_addr,apb_write_addr,
                     output reg sel1,sel2,
                     output reg pwrite,penable,
                     output reg [7:0]pwdata,apb_read_data_out,
                     output reg [8:0] paddr );

                     localparam  idle = 2'b00 ,setup = 2'b01,access = 2'b10;
                     reg [1:0] state,next_state;

                     always @(posedge clk or negedge rst_n)begin

                         if(!rst_n)begin

                             state <= idle;
                             apb_read_data_out <= 0;

                         end

                         else begin

                            state <= next_state;

                           if(state == access && pready && read_write)

                              apb_read_data_out <= prdata;

                      end
                  end

                  always @(*)begin

                     state = next_state;
                     penable = 0;
                     sel1 = 0;
                     sel2 = 0;
                     pwdata = 0;
                     paddr = 0;
                     pwrite = 0;

                    case(state) 

                        idle:begin

                           if(transfer)

                               next_state = setup;
                           else 

                               next_state = idle;
                       end

                       setup:begin

                           penable = 0;
                           pwrite = ~read_write;

                           if(read_write)begin

                               paddr = apb_read_addr;
                               pwdata = 0;

                           end

                           else begin

                               paddr = apb_write_addr;
                               pwdata = apb_write_data;

                           end


                           if(paddr[8] == 1'b0)begin

                               sel1 = 1;
                               sel2 = 0;

                           end
                           
                           else begin

                               sel1 = 0;
                               sel2 = 1;

                           end

                           next_state = access;

                       end

                       access : begin

                           penable = 1;
                           pwrite = ~read_write;

                           if(read_write)begin

                               paddr = apb_read_addr;
                               pwdata = 0;

                           end

                           else begin

                               paddr = apb_write_addr;
                               pwdata = apb_write_data;

                           end

                           if(paddr[8] == 1'b0)begin

                               sel1 = 1;
                               sel2 = 0;

                           end

                           else begin

                               sel1 = 0;
                               sel2 = 1;

                           end

                           if(pready)begin

                               if(transfer)

                                   next_state = setup;
                               else 

                                   next_state = idle;

                           end

                           else 

                               next_state = access;

                       end

                       default : next_state = idle;

                   endcase

               end

endmodule







                               

                               






                             
