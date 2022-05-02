// Description:  parameterized CNN accelerator for one layer
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-30
// Updated on: 2020-05-01: config_data related

module conv_tiled 
#(
  // parameter for tiling for MAC
  parameter IC0 = 4,
  parameter OC0 = 4,
  parameter PARAM_NUM = 6,
  parameter PARAM_WID = 16,
  parameter BANK_ADDR_WIDTH = 32       // width needed to save IC1*IX0*IY0, OY1_OX1

) 
(
  input clk,
  input rst_n,
    
  // ifmap
  input logic [15:0] ifmap_dat,
  output logic ifmap_rdy,
  input logic ifmap_vld,

  // weights
  input logic [15:0] weights_dat,
  output logic  weights_rdy,
  input logic weights_vld,

  // ofmap
  output logic [31:0] ofmap_dat,
  input logic ofmap_rdy,
  output logic ofmap_vld,
    
  // params
  input logic [ PARAM_NUM * PARAM_WID - 1 : 0] layer_params_dat,  // {OY1, OC1, IC1, FY, OY0, stride}
  output logic layer_params_rdy,
  input logic layer_params_vld
);


// local parameters ++

// for layer configuration
logic config_en;
logic [PARAM_WID - 1 : 0] config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE;
logic [PARAM_WID - 1 : 0] config_IY0;

// for ifmap_read_addr_gen
logic [8 * PARAM_WID - 1 : 0] config_data_ifmap_read;

// for ifmap_write_addr_gen
logic [BANK_ADDR_WIDTH - 1 : 0] config_IC1_IY0_IX0;

// for write_bank_counter in ifmap_input_controller
logic [BANK_ADDR_WIDTH - 1 : 0] config_OY1_OX1;

// for weight_addr_gen
logic [BANK_ADDR_WIDTH - 1 : 0] config_data_weight_read;

// for accum_addr_gen
logic [BANK_ADDR_WIDTH - 1 : 0] config_OY0_OX0;

// local parameters --




/*    assignment for config data   */
// derive iy0 from oy0 
assign config_IY0 = config_STRIDE * (config_OY0 - 1) + config_FY;

assign config_data_ifmap_read  = {config_OY0, config_OY0, config_FY, config_FY, 
                                  config_STRIDE, config_IY0, config_IY0, config_IC1}; 
assign config_IC1_IY0_IX0      = config_IC1 * config_IY0 * config_IY0;
assign config_OY1_OX1          = config_OY1 * config_OY1;
assign config_data_weight_read = config_OC1 * config_IC1 * config_FY * config_FY * config_IC0;
assign config_OY0_OX0          = config_OY0 * config_OY0;



/*  load config data  */
always @ (posedge clk) begin
  if (~rst_n)
    {config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE} <= {PARAM_NUM * PARAM_WID {1'b0}};
  else if (config_en)
    {config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE} <= layer_params_dat;
end

endmodule
