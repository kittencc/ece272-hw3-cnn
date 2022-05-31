// Description: main finite-sate-machine for the tiled CNN accelerator
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-05-30


module main_FSM(

  input logic clk,
  input logic rst_n,

  input logic config_done,
  input logic first_oy1_ox1_iter_done,   //oy1_ox1_counter > 0
  input logic ic1_fy_fx_iter_done,
  input logic all_ifmap_write_bank_done,
  input logic oc1_iter_done,
  input logic last_oy1_ox1,

  input logic ifmap_write_bank_ready_to_switch,     // from ifmap_input_controller
  input logic weight_write_bank_ready_to_switch,
  input logic ofmap_read_bank_ready_to_switch,

  output logic layer_params_rdy,       // rdy signal to config the layer parameters
  output logic ifmap_ready_to_switch,
  output logic ifmap_start_new_write_bank,
  output logic ofmap_ready_to_switch,
  output logic ofmap_start_new_read_bank,
  output logic en_oy0_ox0_counter,
  output logic en_oc1_counter,
  output logic en_mac_op,         // enable MAC operations
  output logic rst_n_mac        // rst signal mac_more module

);


// local parameters
localparam RESET = 4'b0000;
localparam CONFIG = 4'b0001;
localparam WAIT2 = 4'b0010;
localparam IFMAP_DOUBLE_BUFFER_SWITCH = 4'b0011;
localparam WRITE_IFMAP = 4'b0100;
localparam MAC_ON = 4'b0101;
localparam WAIT1 = 4'b0110;
localparam OFMAP_DOUBLE_BUFFER_SWITCH = 4'b0111;
localparam OUTPUT_OFMAP = 4'b1000;
localparam END_WAIT = 4'b1001;


// local signals
logic [3:0] state;
logic [3:0] next_state;


// assigning state
always @( posedge clk ) begin
  if (!rst_n)
    state <= RESET;
  else
    state <= next_state;
end



// determining next_state
always @ ( * ) begin
  casez (state)
    RESET:
      if (rst_n)
        next_state <= CONFIG;
      else
        next_state <= RESET;
    CONFIG:
      if (config_done)
        next_state <= WAIT2;
      else
        next_state <= CONFIG;
    WAIT2:
      if (!ifmap_write_bank_ready_to_switch)
        next_state <= WAIT2;
      else if (first_oy1_ox1_iter_done || weight_write_bank_ready_to_switch)
        next_state <= IFMAP_DOUBLE_BUFFER_SWITCH;
      else
        next_state <= WAIT2;
    IFMAP_DOUBLE_BUFFER_SWITCH:
      if (all_ifmap_write_bank_done)
        next_state <= MAC_ON;
      else
        next_state <= WRITE_IFMAP;
    WRITE_IFMAP:
      next_state <= MAC_ON;
    MAC_ON:
      if (ic1_fy_fx_iter_done)
        next_state <= WAIT1;
      else
        next_state <= MAC_ON;
    WAIT1:
      if (ofmap_read_bank_ready_to_switch)
        next_state <= OFMAP_DOUBLE_BUFFER_SWITCH;
      else
        next_state <= WAIT1;
    OFMAP_DOUBLE_BUFFER_SWITCH:
      next_state <= OUTPUT_OFMAP;
    OUTPUT_OFMAP:
      if (!oc1_iter_done)
        next_state <= MAC_ON;
      else if (last_oy1_ox1)
        next_state <= END_WAIT;
      else
        next_state <= WAIT2;
    END_WAIT:
      next_state <= END_WAIT;
  endcase
end



// operations for each states
always @ ( * ) begin
  casez (state)
    RESET:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b0;
      end
    CONFIG:
      begin
        layer_params_rdy           <= 1'b1;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
    WAIT2:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
    IFMAP_DOUBLE_BUFFER_SWITCH:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b1;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
    WRITE_IFMAP:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b1;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
    MAC_ON:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b1;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b1;
        rst_n_mac                  <= 1'b1;
      end
    WAIT1:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b0;
      end
    OFMAP_DOUBLE_BUFFER_SWITCH:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b1;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
    OUTPUT_OFMAP:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b1;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b1;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
    END_WAIT:
      begin
        layer_params_rdy           <= 1'b0;
        ifmap_ready_to_switch      <= 1'b0;
        ifmap_start_new_write_bank <= 1'b0;
        ofmap_ready_to_switch      <= 1'b0;
        ofmap_start_new_read_bank  <= 1'b0;
        en_oy0_ox0_counter         <= 1'b0;
        en_oc1_counter             <= 1'b0;
        en_mac_op                  <= 1'b0;
        rst_n_mac                  <= 1'b1;
      end
  endcase
end



endmodule
