// Description:  parameterized CNN accelerator for one layer
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-30
// Updated on: 2020-05-01: config_data related
// Updated on: 2022-05-15: connect ifmap/weight/ofmap_controller, MAC_more
//                         modules

module conv_tiled
#(
  // parameter for tiling for MAC
  parameter IC0 = 4,
  parameter OC0 = 4,
  parameter PARAM_NUM = 6,
  parameter PARAM_WID = 16,
  parameter BANK_ADDR_WIDTH = 32,       // width needed to save IC1*IX0*IY0, OY1_OX1
  parameter BUFFER_MEM_DEPTH = 256     // capacity of the memory, larger than IC1*Ix0*IY0

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

/*    for layer configuration    */
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



/*    for double buffers   */
// for the ifmap_double_buffer
logic ifmap_double_buffer_ren;
logic [BANK_ADDR_WIDTH - 1 : 0] ifmap_double_buffer_raddr;
logic [16*IC0 - 1 : 0] ifmap_double_buffer_rdata;
logic [BANK_ADDR_WIDTH - 1 : 0] ifmap_write_bank_count;

// for the weight_double_buffer
logic weight_double_buffer_ren;
logic [BANK_ADDR_WIDTH - 1 : 0] weight_double_buffer_raddr;
logic [16*OC0 - 1 : 0] weight_double_buffer_rdata;
logic [ BANK_ADDR_WIDTH- 1 : 0] weight_write_bank_count;


/*  for main FSM  */
// for ifmap_double_buffer
logic ifmap_ready_to_switch;
logic ifmap_start_new_write_bank;
logic ifmap_write_bank_ready_to_switch;       // to main_FSM

// for weight_double_buffer
logic weight_ready_to_switch;
logic weight_start_new_write_bank;
logic weight_write_bank_ready_to_switch;


// flag for config_state
logic config_done;



// local parameters --




/*    assignment for config data   */
// derive iy0 from oy0
assign config_IY0 = config_STRIDE * (config_OY0 - 1) + config_FY;

assign config_data_ifmap_read  = {config_OY0, config_OY0, config_FY, config_FY,
                                  config_STRIDE, config_IY0, config_IY0, config_IC1};
assign config_IC1_IY0_IX0      = config_IC1 * config_IY0 * config_IY0;
assign config_OY1_OX1          = config_OY1 * config_OY1;
assign config_data_weight_read = config_OC1 * config_IC1 * config_FY * config_FY * IC0;
assign config_OY0_OX0          = config_OY0 * config_OY0;



/*  load config data  */
always @ (posedge clk) begin
  if (~rst_n)
    {config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE} <= {PARAM_NUM * PARAM_WID {1'b0}};
  else if (config_en)
    {config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE} <= layer_params_dat;
end





/* connect ifmap_input_controller module */
ifmap_input_controller
# (
  .IC0(IC0),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),        // width needed to save IC1*IX0*IY0, OY1_OX1
  .BUFFER_MEM_DEPTH(BUFFER_MEM_DEPTH)     // capacity of the memory, larger than IC1*Ix0*IY0
)
ifmap_input_controller_inst
(
  .clk(clk),
  .rst_n(rst_n),

  // for ifmap_chaining
  .input_dat(ifmap_dat),
  .input_vld(ifmap_vld),
  .input_rdy(ifmap_rdy),

  // for the config parameters
  .config_IC1_IY0_IX0(config_IC1_IY0_IX0),
  .config_OY1_OX1(config_OY1_OX1),

// for the ifmap_double_buffer
  .ren(ifmap_double_buffer_ren),
  .raddr(ifmap_double_buffer_raddr),
  .rdata(ifmap_double_buffer_rdata),

// for the controller FSM
  .ready_to_switch(ifmap_ready_to_switch),         // from main FSM
  .start_new_write_bank(ifmap_start_new_write_bank),    // from main FSM
  .config_done(config_done),           // flag from the top module

//  output logic one_write_bank_done
  .write_bank_ready_to_switch(ifmap_write_bank_ready_to_switch),   // to main_FSM
  .write_bank_count(ifmap_write_bank_count)  // # of write bands completed

);


/*  connect the weight_input_controller  */
weight_input_controller
# (
  .OC0(OC0),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),        // width needed to save OC1*IC1*FY*FX*OC0
  .BUFFER_MEM_DEPTH(BUFFER_MEM_DEPTH)     // capacity of the memory, larger than IC1*Ix0*IY0
)
weight_input_controller_inst
(
  .clk(clk),
  .rst_n(rst_n),

  // for weight_chaining
  .input_dat(weights_dat),
  .input_vld(weights_vld),
  .input_rdy(weights_rdy),

  // for the config parameters
  .config_data_weight_read(config_data_weight_read),

// for the weight_double_buffer
  .ren(weight_double_buffer_ren),
  .raddr(weight_double_buffer_raddr),
  .rdata(weight_double_buffer_rdata),

// for the controller FSM
  .ready_to_switch(weight_ready_to_switch),                   // from main FSM
  .start_new_write_bank(weight_start_new_write_bank),          // from main FSM
  .config_done(config_done),           // flag from the top module

//  output logic one_write_bank_done
  .write_bank_ready_to_switch(weight_write_bank_ready_to_switch),   // to main_FSM
  .write_bank_count(weight_write_bank_count)

);
endmodule
