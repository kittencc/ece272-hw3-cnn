// Description: A parameterized counter. Count up to MAX_COUNT - 1
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-08
// Updated on 2022-04-30
//  - Changes MAX_COUNT from a parameter to a input signal
//   -- the counter here tracks the progress reading/writing to double
//      buffers.
//   -- the size of the double buffer, e.g. IC1*IY0*IX0 for the
//       ifmap_double_buffer, should be able to change post Si
//       fabrication. 
//   -- It makes more sense for it to be a signal rather than a parameter
//      (STATIC).
//   -- config_MAX_COUNT needs to be set before enabling the counter!!!


module counter 
#(
  parameter COUNTER_WID = 8
)
(
  input logic clk,
  input logic rst_n,
  input logic en,
  output logic [COUNTER_WID-1: 0] count,
  input logic [COUNTER_WID-1: 0] config_MAX_COUNT
);


// logic for counting
always @ (posedge clk) begin
  if (~rst_n) count <= 0;
  else if (en) begin
    if ( count == (config_MAX_COUNT - 1))
      count <= 0;
    else
      count <= count + 1;
  end
end




endmodule
