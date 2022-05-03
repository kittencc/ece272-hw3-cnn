// Description: Addr generation logic for reading ifmap data from the
// double buffer.
// Author: Cheryl (Yingqiu) Cao
// Updated on: 2022-05-02: config_data loading logic moved to top level


module input_read_addr_gen
#(
  parameter PARAM_WID = 16,
  parameter NUM_PARAMS = 8,
  parameter BANK_ADDR_WIDTH = 8
)(
  input clk,
  input rst_n,
  input addr_enable,
  output [BANK_ADDR_WIDTH - 1 : 0] addr,
  input [PARAM_WID*NUM_PARAMS - 1 : 0] config_data
);

// local signals
  logic [PARAM_WID - 1 : 0] config_OX0, config_OY0, config_FX, config_FY,
    config_STRIDE, config_IX0, config_IY0, config_IC1;
  logic [PARAM_WID - 1 : 0] ox0, oy0, fx, fy, ic1;
  logic [PARAM_WID - 1 : 0] ix0, iy0, addrc;


  assign {config_OX0, config_OY0, config_FX, config_FY,
          config_STRIDE, config_IX0, config_IY0, config_IC1} = config_data;
  assign ix0 = config_STRIDE * ox0 + fx;
  assign iy0 = config_STRIDE * oy0 + fy;
  assign addrc = ic1 * config_IX0 * config_IY0 + iy0 * config_IX0 + ix0;

  assign addr = addrc[BANK_ADDR_WIDTH - 1 : 0];




  always @ (posedge clk) begin
    if (rst_n) begin
      if (addr_enable) begin
        ox0 <=  (ox0 == config_OX0 - 1) ?
          0 : ox0 + 1;
        oy0 <=  (ox0 == config_OX0 - 1) ?
          ((oy0 == config_OY0 - 1) ? 0 : oy0 + 1) : oy0;
        fx  <= ((ox0 == config_OX0 - 1) && (oy0 == config_OY0 - 1)) ?
          ((fx == config_FX - 1) ? 0 : fx + 1) : fx;
        fy  <= ((ox0 == config_OX0 - 1) && (oy0 == config_OY0 - 1) && (fx == config_FX - 1)) ?
          ((fy == config_FY - 1) ? 0 : fy + 1) : fy;
        ic1 <= ((ox0 == config_OX0 - 1) && (oy0 == config_OY0 - 1) && (fx == config_FX - 1) && (fy == config_FY - 1)) ?
          ((ic1 == config_IC1 - 1) ? 0 : ic1 + 1) : ic1;
      end
    end else begin
      ox0 <= 0;
      oy0 <= 0;
      fx <= 0;
      fy <= 0;
      ic1 <= 0;
    end
  end

endmodule
