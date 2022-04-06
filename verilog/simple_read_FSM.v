// the FSM that controls data readout from a double buffer
// This will be used as the base for the ofmap_read_FSM for the CNN
//
// In the CNN, the readout of ifmap/weights data from the double buffer
// needs to be synchronized by the main_FSM. However, the ofmap readout is
// relatively independent. Therefore I'm gonna separate it for coding
// moduality.
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-02


module simple_read_FSM(

  input logic clk,
  input logic rst_n,
  input logic start_new_read_bank,
  input logic reading_last_data,   // from the double buffer
  
  // for the read addr gen module
  output logic config_enable,            // for the addr gen module
  output logic addr_enable,              // en signal for the addr gen module
  // for the read controllder
  output logic one_read_bank_done,
  output logic read_bank_ready_to_switch

);

// local parameters
localparam RESET           = 3'b000;
localparam CONFIG          = 3'b001;
localparam WAIT            = 3'b010;
localparam READ            = 3'b011;
localparam READ_BANK_COUNT = 3'b100;


// local signals
logic [2:0] state;
logic [2:0] next_state;


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
      if (rst_n)    // not reset
        next_state <= CONFIG;
      else
        next_state <= RESET;
    CONFIG:
      next_state <= WAIT;
    WAIT:
      if (start_new_read_bank)
        next_state <= READ;
      else
        next_state <= WAIT;
    READ:
      if (reading_last_data)
        next_state <= READ_BANK_COUNT;
      else
        next_state <= READ;
    READ_BANK_COUNT:
      next_state <= WAIT;
    default:
      next_state <= RESET;      // should never happen
  endcase
end



// operations for each states
always @ ( * ) begin
  casez (state)
    RESET:
      begin
        config_enable             <= 1'b0;
        addr_enable               <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    CONFIG:
      begin
        config_enable             <= 1'b1;
        addr_enable               <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
     end
    WAIT:
      begin
        config_enable             <= 1'b0;
        addr_enable               <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b1;
      end
    READ:
      begin
        config_enable             <= 1'b0;
        addr_enable               <= 1'b1;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    READ_BANK_COUNT:
      begin
        config_enable             <= 1'b0;
        addr_enable               <= 1'b0;
        one_read_bank_done        <= 1'b1;
        read_bank_ready_to_switch <= 1'b0;
     end


  endcase
end


endmodule




