// a 2:1 mux
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-07


module mux2
#(
  parameter DATA_WIDTH = 1
)
(

  input logic sel,
  input logic [DATA_WIDTH-1:0] in1,    // select in1 when sel = 0
  input logic  [DATA_WIDTH-1:0] in2,
  output logic [DATA_WIDTH-1:0] out

);

assign out = sel? in2 : in1;


endmodule
