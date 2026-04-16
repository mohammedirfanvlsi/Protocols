module tx_baud_generator #(
  parameter sys_clk = 50_000_000, 
  parameter baud_rate = 9600
) (
  input clk, rst, baud_en,
  output reg tx_tick
);
  localparam integer tx_cycle = sys_clk / baud_rate; // transmitter cycle
  
  localparam tx_bit = $clog2(tx_cycle); //transmission bit size to complete the cycle
  
  reg [tx_bit-1: 0] tx_count;
  
  always @(posedge clk or negedge rst) begin // generating transmission tick
    
    if(!rst) begin
      tx_count<=0;
      tx_tick<=0;
    end
    
    else if (baud_en) begin
    
      if (tx_count == tx_cycle - 1) begin
        tx_count<=0;
        tx_tick<=1;
      end
      
      else begin
        tx_count<=tx_count+1;
        tx_tick<=0;
      end
      
    end
    
  end
  
endmodule