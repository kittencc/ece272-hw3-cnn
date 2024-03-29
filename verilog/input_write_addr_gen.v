// Author: Cheryl (Yingqiu) Cao
// Initial update on: 2021-12-27
// update on: 2021-12-31
// updated on: 2022-05-01:  config_data loading logic moved to top level
//                           module

module input_write_addr_gen
#(
  parameter BANK_ADDR_WIDTH = 32
)(
  input logic clk,
  input logic rst_n,
  input logic addr_enable,
  input logic [BANK_ADDR_WIDTH - 1 : 0] config_data,

  output logic [BANK_ADDR_WIDTH - 1 : 0] addr,
  output logic writing_last_data

);

  // The address generator receives some configuration data at the beginning
  // of the convolution which sets the layer and schedule parameters in
  // registers inside it.

  logic [BANK_ADDR_WIDTH - 1 : 0] config_IC1_IY0_IX0;
  logic [BANK_ADDR_WIDTH - 1 : 0] ic1_iy0_ix0;      // saves the current addr
  logic last_input_write_addr;                     // high if the current addr is the last one

  assign config_IC1_IY0_IX0 = config_data;
  assign last_input_write_addr = (ic1_iy0_ix0 == config_IC1_IY0_IX0 - 1);
  assign writing_last_data = addr_enable && last_input_write_addr;  // writing the last data in the bank the current cycle (done next cycle)



  // The core logic basically consists of a set of nested counters that
  // generate addresses according to the configuration. There is an
  // addr_enable signal coming from the top level that asks the addr_gen to
  // step (produce the next address). Make sure that you hold addr_enable
  // low during config, or more generally anytime you want to stall.


  always @ (posedge clk) begin
    if (rst_n) begin
      if (addr_enable) begin
        // One block coming into the input double buffer is IC1 * IY0 * IX0 deep and
        // IC0*IFMAP_WIDTH wide, so the counter below just counts up to this
        // depth and then resets to 0 for the next block.

        ic1_iy0_ix0 <= (ic1_iy0_ix0 == config_IC1_IY0_IX0 - 1) ? 0 : ic1_iy0_ix0 + 1;

        // The difficult part here is to make sure that the input blocks have
        // the right overlap as explained in the homework pdf along IY0 and
        // IX0, but it is the responsibility of the testbench to make sure
        // that happens, so your addressing logic is simplified.
      end
    end else begin
      ic1_iy0_ix0 <= 0;
    end
  end

  assign addr = ic1_iy0_ix0;

endmodule
