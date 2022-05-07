// Description: addr generation for accum double buffer
//              The read order is the same as the write order
//              The addr increments from 0 to (OY0_OX0 - 1).
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-6
// Updated on 2022-05-07: config_data loading logic moved to top level


module accum_addr_gen
# (
  parameter BANK_ADDR_WIDTH = 32
)
(
  input logic clk,
  input logic rst_n,
  input logic addr_enable,
  input logic [BANK_ADDR_WIDTH - 1 : 0] config_data,

  output logic [BANK_ADDR_WIDTH - 1 : 0] addr,
  output logic writing_last_data

);


  logic [BANK_ADDR_WIDTH - 1 : 0] config_OY0_OX0;
  logic [BANK_ADDR_WIDTH - 1 : 0] oy0_ox0;      // saves the current addr
  logic last_input_write_addr;                     // high if the current addr is the last one

  assign config_OY0_OX0 = config_data;
  assign last_input_write_addr = (oy0_ox0 == config_OY0_OX0 - 1);
  assign writing_last_data = addr_enable && last_input_write_addr;  // writing the last data in the bank the current cycle (done next cycle)





  always @ (posedge clk) begin
    if (rst_n) begin
      if (addr_enable) begin
        // One block coming into the input double buffer is  OY0 * OX0 deep and
        // OC0*OFMAP_WIDTH wide, so the counter below just counts up to this
        // depth and then resets to 0 for the next block.
        oy0_ox0 <= last_input_write_addr ? 0 : oy0_ox0 + 1;
      end
    end else begin
      oy0_ox0 <= 0;
    end
  end

  assign addr = oy0_ox0;


endmodule
