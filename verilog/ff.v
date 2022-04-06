//D flip-flop with rst_n and en, parameterized data width
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-07


module ff
#(
  parameter DATA_WIDTH = 1
)
(

  input logic                   rst_n,
  input logic                   en,
  input logic                   clk,
  input logic  [DATA_WIDTH-1:0] D,
  output logic [DATA_WIDTH-1:0] Q

);


always@( posedge clk ) begin
  if (~rst_n) 
    Q <= {DATA_WIDTH {1'b0}};
  else if (en)
    Q <= D;
end


endmodule
