// Author: Cheryl(Yingqiu) Cao
// Date: 2022-04-02

module mac
#(
  parameter IFMAP_WIDTH = 16,     // ifmap data width
  parameter WEIGHT_WIDTH = 16,
  parameter OFMAP_WIDTH = 32
)(
  input logic  clk,
  input logic  rst_n,
  input logic  en,            // en for the entire mac module
  input logic  en_weight,     // en signal for the weight FF
  input logic  [IFMAP_WIDTH - 1 : 0]  ifmap_in,
  input logic  [WEIGHT_WIDTH - 1 : 0] weight_in,
  input logic  [OFMAP_WIDTH - 1 : 0]  accum_in,
  output logic  [IFMAP_WIDTH - 1 : 0] ifmap_out,
  output logic  [OFMAP_WIDTH - 1 : 0] accum_out
);

// local variables
logic  [WEIGHT_WIDTH - 1 : 0] weight_q;
logic [OFMAP_WIDTH - 1 : 0] product;
logic [OFMAP_WIDTH - 1 : 0] sum_d; 

// weight FF
always @ ( posedge clk ) begin
  if (~rst_n)
    weight_q = {WEIGHT_WIDTH {1'b0}};   // concatenated 1 bit 0s
  else if (en_weight)
    weight_q = weight_in;
end
    
// input FF  
always @ ( posedge clk ) begin
  if (~rst_n)
    ifmap_out = {IFMAP_WIDTH {1'b0}};   // concatenated 1 bit 0s
  else if (en)
    ifmap_out = ifmap_in;
end

// calculation
assign product = weight_q * ifmap_in;
assign sum_d = product + accum_in;

// accum sum FF
always @ ( posedge clk ) begin
  if (~rst_n)
    accum_out = {OFMAP_WIDTH {1'b0}};   // concatenated 1 bit 0s
  else if (en)
    accum_out = sum_d;
end



endmodule


