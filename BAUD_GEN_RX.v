module rx_baud_generator #(
  parameter sys_clk = 50_000_000, 
  parameter baud_rate = 9600
) (
  input clk, rst, baud_en,
  output reg rx_tick
);
  localparam integer rx_cycle = sys_clk / ( baud_rate * 16); // receiver cycle
 
  localparam rx_bit = $clog2(rx_cycle); //receiving bit size to complete the cycle
  
  reg [rx_bit-1: 0] rx_count;
  
  always @(posedge clk or negedge rst) begin // generating transmission tick
    
    if(!rst) begin
      rx_count<=0;
      rx_tick<=0;
    end
    
    else if (baud_en) begin
    
      if (rx_count == rx_cycle - 1) begin
        rx_count<=0;
        rx_tick<=1;
      end
      
      else begin
        rx_count<=rx_count+1;
        rx_tick<=0;
      end
      
    end
    
  end
  
endmodule