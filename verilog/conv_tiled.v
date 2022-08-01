// Description:  parameterized CNN accelerator for one layer
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-30
// Updated on: 2020-05-01: config_data related
// Updated on: 2022-05-15:
//      - connect ifmap/weight/ofmap_controller, MAC_more
//                         modules
// Updated on: 2022-05-29:
//      - connect counters
// Updated on: 2022-05-30:
//      - connect main_FSM
//      - add logic for counter iter states
//      - add logic for mac_more module
// Updated on: 2022-06-11:
//      - connect ifmap/weight_read_addr_gen, accum_write/read_addr_gen  modules
//      - add logic for ren/wen signals for
//      ifmap/weight/accum_double_buffer
//      - add logic to load config_data

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



// local signals ++

/*    for layer configuration    */
logic config_en;
logic [PARAM_WID - 1 : 0] config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE;
logic [PARAM_WID - 1 : 0] config_IY0;

// for ifmap_read_addr_gen
logic [8 * PARAM_WID - 1 : 0]   config_data_ifmap_read;
// for ifmap_write_addr_gen
logic [BANK_ADDR_WIDTH - 1 : 0] config_IC1_IY0_IX0;
// for write_bank_counter in ifmap_input_controller
logic [BANK_ADDR_WIDTH - 1 : 0] config_OY1_OX1;
// for weight_addr_gen
logic [BANK_ADDR_WIDTH - 1 : 0] config_data_weight_read;
// for accum_addr_gen
logic [BANK_ADDR_WIDTH - 1 : 0] config_OY0_OX0;
// for read_bank_counter in ofmap_output_controleer
logic [BANK_ADDR_WIDTH - 1 : 0] config_OY1_OX1_OC1;
// for mac_more iteration
logic [BANK_ADDR_WIDTH - 1 : 0] config_IC1_FY_FX;




/*    for double buffers   */
// for the ifmap_double_buffer
logic                           ifmap_double_buffer_ren;
logic [BANK_ADDR_WIDTH - 1 : 0] ifmap_double_buffer_raddr;
logic [16*IC0 - 1 : 0]          ifmap_double_buffer_rdata;
logic [BANK_ADDR_WIDTH - 1 : 0] ifmap_write_bank_count;

// for the weight_double_buffer
logic                           weight_double_buffer_ren;
logic [BANK_ADDR_WIDTH - 1 : 0] weight_double_buffer_raddr;
logic [16*OC0 - 1 : 0]          weight_double_buffer_rdata;
logic [ BANK_ADDR_WIDTH- 1 : 0] weight_write_bank_count;

// for accum_double_buffer
  // 1 read 1 write ports for the mac array and the accum sum
logic                           accum_double_buffer_wen;
logic [BANK_ADDR_WIDTH - 1 : 0] accum_double_buffer_waddr;
logic [32*OC0 - 1 : 0]          accum_double_buffer_wdata;
logic                           accum_double_buffer_ren;
logic [BANK_ADDR_WIDTH - 1 : 0] accum_double_buffer_raddr;
logic [32*OC0 - 1 : 0]          accum_double_buffer_rdata;
logic [BANK_ADDR_WIDTH - 1 : 0] ofmap_read_bank_count;



/*  for mac_more module */
logic rst_n_mac;          // so as to reset just the mac array
logic en_mac_op;          // enable general operations
logic en_weight00;   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
logic ifmap_fifo_enq;
logic weight_fifo_enq;
logic accum_in_fifo_enq;
logic accum_out_fifo_enq;



/*  for main FSM  */
// for ifmap_double_buffer
logic ifmap_ready_to_switch;
logic ifmap_start_new_write_bank;
logic ifmap_write_bank_ready_to_switch;       // to main_FSM
logic all_ifmap_write_bank_done;              // to main_FSM

// for weight_double_buffer
logic weight_ready_to_switch;
logic weight_start_new_write_bank;
logic weight_write_bank_ready_to_switch;

// accum_fouble_buffer
logic ofmap_ready_to_switch;       // from main FSM
logic ofmap_start_new_read_bank;  // output ofmap to testbench
logic ofmap_read_bank_ready_to_switch;  // to main FSM

// flag for config_state
logic config_done;

// for counters
logic en_oy0_ox0_counter;
logic en_oc1_counter;




/* for the counters  */
logic en_ic1_fy_fx_counter;
logic en_oy1_ox1_counter;
logic first_oy1_ox1_iter_done;
logic last_oy1_ox1;
logic ic1_fy_fx_iter_done;
logic ic1_fy_fx_not_last_cycle;
logic ic1_fy_fx_not_zero_cycle;
logic ic1_fy_fx_not_zero_or_last_cycle;
logic oc1_iter_done;
logic oy0_ox0_first_cycle;
logic oy0_ox0_not_zero_cycle;
logic oy0_ox0_last_cycle;
logic oy0_ox0_not_last2_cycle;


logic [BANK_ADDR_WIDTH - 1 : 0] oy0_ox0;   // the current iteration for oy0_ox0
logic [BANK_ADDR_WIDTH - 1 : 0] ic1_fy_fx;
logic [PARAM_WID - 1 : 0]        oc1;
logic [BANK_ADDR_WIDTH - 1 : 0] oy1_ox1;




// local signals --




/*  assignment for counter en signals  */
assign en_ic1_fy_fx_counter    = oy0_ox0_last_cycle;
assign en_oy1_ox1_counter      = oc1_iter_done;

/*  assignment for iteration states   */
// oy0_ox0 related
assign oy0_ox0_first_cycle = (oy0_ox0 == 1);
assign oy0_ox0_not_zero_cycle = (oy0_ox0 > 0);
assign oy0_ox0_last_cycle = (oy0_ox0 == config_OY0_OX0);
assign oy0_ox0_not_last2_cycle = (oy0_ox0 < (config_OY0_OX0 - 1));

//ic1_fy_fx related
assign ic1_fy_fx_iter_done     = (ic1_fy_fx == config_IC1_FY_FX) && en_ic1_fy_fx_counter;
assign ic1_fy_fx_not_last_cycle = (ic1_fy_fx < config_IC1_FY_FX);
assign ic1_fy_fx_not_zero_cycle = (ic1_fy_fx > 0);
assign ic1_fy_fx_not_zero_or_last_cycle = ic1_fy_fx_not_zero_cycle && ic1_fy_fx_not_last_cycle;

// oc1_related
assign oc1_iter_done           = (oc1 == (config_OC1-1)) && en_oc1_counter;

// oy1_ox1 related
assign last_oy1_ox1            = (oy1_ox1 == (config_OY1_OX1-1));
assign first_oy1_ox1_iter_done = (oy1_ox1 > 0);



/* assignment for ifmap_write_bank_counter   */
assign all_ifmap_write_bank_done = (ifmap_write_bank_count == config_OY1_OX1);

/* assignment for weight_double_buffer   */
assign weight_ready_to_switch = (ifmap_ready_to_switch && (oy1_ox1 == 0) );  // only need to write to the weight banks once, as this is a weight stationary design
assign weight_start_new_write_bank = 1'b0;    // no need to write to the weight bank for more than once 




/*    assignment for config data   */
// derive iy0 from oy0
assign config_IY0              = config_STRIDE * (config_OY0 - 1) + config_FY;
assign config_data_ifmap_read  = {config_OY0, config_OY0, config_FY, config_FY,
                                  config_STRIDE, config_IY0, config_IY0, config_IC1};
assign config_IC1_IY0_IX0      = config_IC1 * config_IY0 * config_IY0;
assign config_OY1_OX1          = config_OY1 * config_OY1;
assign config_data_weight_read = config_OC1 * config_IC1 * config_FY * config_FY * IC0;
assign config_OY0_OX0          = config_OY0 * config_OY0;
assign config_OY1_OX1_OC1      = config_OY1 * config_OY1 * config_OC1;
assign config_IC1_FY_FX        = config_IC1 * config_FY * config_FY;



/*    logic for mac_more module     */
// for en_weight00
always @ (*) begin
  if (en_mac_op)
    en_weight00 <= ic1_fy_fx_not_last_cycle && oy0_ox0_first_cycle;
  else
    en_weight00 <= 1'b0;
end

// for weight_fifo_enq
always @ (*) begin
  if (en_mac_op)
    weight_fifo_enq<= (ic1_fy_fx_not_last_cycle && oy0_ox0_not_zero_cycle && (oy0_ox0 <= IC0));
  else
    weight_fifo_enq<= 1'b0;
end

// for ifmap_fifo_enq
always @ (*) begin
  if (en_mac_op)
    ifmap_fifo_enq <= ic1_fy_fx_not_last_cycle && (~oy0_ox0_first_cycle);
  else
    ifmap_fifo_enq <= 1'b0;
end

// for accum_in_fifo_enq
always @ (*) begin
  if (en_mac_op)
    accum_in_fifo_enq <= ic1_fy_fx_not_zero_or_last_cycle && (~oy0_ox0_first_cycle);
  else
    accum_in_fifo_enq <= 1'b0;
end

// for accum_out_fifo_enq
always @ (*) begin
  if (en_mac_op) begin
    if (oy0_ox0 <= IC0)
      accum_out_fifo_enq <= ic1_fy_fx_not_zero_cycle;
    else if (oy0_ox0 > (IC0 + 1))
      accum_out_fifo_enq <= ic1_fy_fx_not_last_cycle;
    else
      accum_out_fifo_enq <= 1'b0;
  end
  else
    accum_out_fifo_enq <= 1'b0;
end




/* logic for ifmap_double_buffer module*/
always @ (*) begin
  if (en_mac_op)
      ifmap_double_buffer_ren <= ic1_fy_fx_not_last_cycle && oy0_ox0_not_zero_cycle;
  else
      ifmap_double_buffer_ren <= 1'b0;
end


/* logic for weight_double_buffer module*/
always @ (*) begin
  if (en_mac_op)
      weight_double_buffer_ren <= ic1_fy_fx_not_last_cycle && (oy0_ox0 < IC0);
  else
      weight_double_buffer_ren <= 1'b0;
end


/* logic for weight_double_buffer module*/
// ren
always @ (*) begin
  if (en_mac_op)
      accum_double_buffer_ren <= ic1_fy_fx_not_zero_or_last_cycle && oy0_ox0_not_zero_cycle;
  else
      accum_double_buffer_ren <= 1'b0;
end

// wen
always @ (*) begin
  if (en_mac_op)
      accum_double_buffer_wen <= (ic1_fy_fx_not_last_cycle && oy0_ox0_last_cycle) || (ic1_fy_fx_not_zero_cycle && oy0_ox0_not_last2_cycle);
  else
      accum_double_buffer_wen <= 1'b0;
end





/*  load config data  */
always @ (posedge clk) begin
  if (~rst_n)
    {config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE} <= { PARAM_NUM* PARAM_WID {1'b0}};
  else if (layer_params_rdy && layer_params_vld )
    {config_OY1, config_OC1, config_IC1, config_FY, config_OY0, config_STRIDE} <= layer_params_dat;
end

/* logic for config_done  flag */
always @ (posedge clk) begin
  if (~rst_n)
    config_done <= 1'b0;
  else if (layer_params_rdy && layer_params_vld )   // _vld signal only stays high for 1 cycle
    config_done <= 1'b1;
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


/*  connect ofmap_output_controller */
ofmap_output_controller
# (
  .OC0(OC0),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),       // width of read/write addr
  .MEM_DEPTH(BUFFER_MEM_DEPTH)     // depth of the accum_double_buffer, larger than OY0 * OX0 = 9

)
ofmap_output_controller_inst
(
  .clk(clk),
  .rst_n(rst_n),

  // for ofmap_PISO
  .ofmap_rdy(ofmap_rdy),
  .ofmap_dat(ofmap_dat),
  .ofmap_vld(ofmap_vld),

  // for accum_double_buffer
  // 1 read 1 write ports for the mac array and the accum sum
  .wen(accum_double_buffer_wen),
  .waddr(accum_double_buffer_waddr),
  .wdata(accum_double_buffer_wdata),
  .ren(accum_double_buffer_ren),
  .raddr_accum(accum_double_buffer_raddr),
  .rdata_accum(accum_double_buffer_rdata),

  // for the config parameters
  .config_OY0_OX0(config_OY0_OX0),   // for ofmap_read_addr_gen
  .config_OY1_OX1_OC1(config_OY1_OX1_OC1),   // for read bank counter

  // for the main FSM
  .config_done(config_done),     // from the top FSM
  .ready_to_switch(ofmap_ready_to_switch),
  .start_new_read_bank(ofmap_start_new_read_bank),
  .read_bank_ready_to_switch(ofmap_read_bank_ready_to_switch),
  .ofmap_read_bank_count(ofmap_read_bank_count)     // the # of ofmap read bank that was completed, up to OY1_OX1_OC1

);



/*   connect mac_more module    */
mac_more
# (
  .IC0(IC0),        // height of the mac array
  .OC0(OC0)         // width of the mac array

)
mac_more_inst
(
  .clk(clk),
  .rst_n(rst_n && rst_n_mac),  // reset on FSM and external signals
  .en(en_mac_op),            // en for the entire mac array
  .en_weight00(en_weight00),   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
  .ifmap_fifo_enq(ifmap_fifo_enq),
  .ifmap_dat_chained_fifo_in(ifmap_double_buffer_rdata),
  .weight_fifo_enq(weight_fifo_enq),
  .weight_dat_chained_fifo_in(weight_double_buffer_rdata),
  .accum_in_fifo_enq(accum_in_fifo_enq),
  .accum_in_chained_fifo_in(accum_double_buffer_rdata),
  .accum_out_fifo_enq(accum_out_fifo_enq),
  .accum_out_chained_fifo_out(accum_double_buffer_wdata)

);



/*   connect main_FSM module    */
main_FSM main_FSM_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .config_done(config_done),
  .first_oy1_ox1_iter_done(first_oy1_ox1_iter_done),
  .ic1_fy_fx_iter_done(ic1_fy_fx_iter_done),
  .all_ifmap_write_bank_done(all_ifmap_write_bank_done),
  .oc1_iter_done(oc1_iter_done),
  .last_oy1_ox1(last_oy1_ox1),
  .ifmap_write_bank_ready_to_switch(ifmap_write_bank_ready_to_switch),
  .weight_write_bank_ready_to_switch(weight_write_bank_ready_to_switch),
  .ofmap_read_bank_ready_to_switch(ofmap_read_bank_ready_to_switch),
  .layer_params_rdy(layer_params_rdy),
  .ifmap_ready_to_switch(ifmap_ready_to_switch),
  .ifmap_start_new_write_bank(ifmap_start_new_write_bank),
  .ofmap_ready_to_switch(ofmap_ready_to_switch),
  .ofmap_start_new_read_bank(ofmap_start_new_read_bank),
  .en_oy0_ox0_counter(en_oy0_ox0_counter),
  .en_oc1_counter(en_oc1_counter),
  .en_mac_op(en_mac_op),
  .rst_n_mac(rst_n_mac)
);




/* connect ifmap_double_buffer read_addr_gen module */
input_read_addr_gen
#(
  .PARAM_WID(PARAM_WID),
  .NUM_PARAMS(8),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
ifmap_read_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(ifmap_double_buffer_ren),
  .addr(ifmap_double_buffer_raddr),
  .config_data(config_data_ifmap_read)
);


/* connect weight_double_buffer read_addr_gen module */
weight_addr_gen
# (
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
weight_read_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(weight_double_buffer_ren),
  .config_data(config_data_weight_read),
  .addr(weight_double_buffer_raddr),
  .writing_last_data(weight_db_reading_last_data)
);


/* connect accum_read_addr_gen module */
accum_addr_gen
# (
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
accum_read_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(accum_double_buffer_ren),
  .config_data(config_OY0_OX0),
  .addr(accum_double_buffer_raddr),
  .writing_last_data(accum_db_reading_last_data)
);

/* connect accum_write_addr_gen module */
accum_addr_gen
# (
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
accum_write_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(accum_double_buffer_wen),
  .config_data(config_OY0_OX0),
  .addr(accum_double_buffer_waddr),
  .writing_last_data(accum_db_writing_last_data)
);




// counter for oy0_ox0 iteration
// count from 0 to OY0_OX0
counter
#(
  .COUNTER_WID(BANK_ADDR_WIDTH)
)
oy0_ox0_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_oy0_ox0_counter),
  .count(oy0_ox0),
  .config_MAX_COUNT(config_OY0_OX0+1)
);


// counter for ic1_fy_fx iteration
// count from 0 to IC1_FY_FX
counter
#(
  .COUNTER_WID(BANK_ADDR_WIDTH)
)
ic1_fy_fx_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_ic1_fy_fx_counter),
  .count(ic1_fy_fx),
  .config_MAX_COUNT(config_IC1_FY_FX + 1)
);


// counter for oc1 iteration
// count from 0 to OC1-1
counter
#(
  .COUNTER_WID(PARAM_WID)
)
oc1_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_oc1_counter),
  .count(oc1),
  .config_MAX_COUNT(config_OC1)
);


// counter for oy1_ox1 iteration
// count from 0 to OY1_OX1-1
counter
#(
  .COUNTER_WID(BANK_ADDR_WIDTH)
)
oy1_ox1_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_oy1_ox1_counter),
  .count(oy1_ox1),
  .config_MAX_COUNT(config_OY1_OX1)
);


endmodule
