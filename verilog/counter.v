// Description: A parameterized counter. Count up to MAX_COUNT - 1
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-08


module counter 
#(
  parameter MAX_COUNT = 4,
  parameter COUNTER_WID = $clog2(MAX_COUNT-1) + 1
)
(
  input logic clk,
  input logic rst_n,
  input logic en,
  output logic [COUNTER_WID-1: 0] count
);


always @ (posedge clk) begin
  if (~rst_n) count <= 0;
  else if (en) begin
    if ( count == MAX_COUNT-1 )
      count <= 0;
    else
      count <= count + 1;
  end
end




endmodule
