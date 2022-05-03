// Description: Addr generation logic for the reading/writing operation of
//               the weight double buffer.
//               Note: that the read/write order of the weights can be the same. So we
//               decided to use the same module for addr gen.
//               - One bank saves OC1 x IC1 x FY x FX x IC0 items
//                               = 4   *  2  * 3  * 3  * 4
//               - Each weight entry is chained over OC0 = 4;
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-3-19
// Updated on 2022-05-02: config_data loading logic moved to top level



module weight_addr_gen
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


  
  logic [BANK_ADDR_WIDTH - 1 : 0] config_OC1_IC1_FY_FX_IC0;
  logic [BANK_ADDR_WIDTH - 1 : 0] index;      // saves the current addr
  logic last_input_write_addr;                     // high if the current addr is the last one


  assign config_OC1_IC1_FY_FX_IC0 = config_data;
  assign last_input_write_addr = (index == config_OC1_IC1_FY_FX_IC0 - 1); 
  assign writing_last_data = addr_enable && last_input_write_addr;  // writing the last data in the bank the current cycle (done next cycle)


   
  always @ (posedge clk) begin
    if (rst_n) begin
      if (addr_enable) begin
        index <= (index == config_OC1_IC1_FY_FX_IC0 - 1) ? 0 : index + 1;
      end
    end else begin
      index <= 0;
    end
  end

  assign addr = index;


endmodule
