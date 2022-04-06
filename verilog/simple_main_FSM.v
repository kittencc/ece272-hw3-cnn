// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-02

module simple_main_FSM(

  input logic clk,
  input logic rst_n,

  input logic read_bank_ready_to_switch,
  input logic write_bank_ready_to_switch,
  input logic is_last_read_bank,
  input logic is_last_write_bank,

  output logic start_new_read_bank,
  output logic start_new_write_bank,
  output logic ready_to_switch
);


// local parameters
localparam RESET = 3'b000;
localparam CONFIG = 3'b001;
localparam WAIT = 3'b010;
localparam SWITCH = 3'b011;
localparam START_W = 3'b100;
localparam START_RW = 3'b101;
localparam START_R = 3'b110;
localparam ENDSTATE = 3'b111;


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
      next_state <= START_W;
    START_W:
      next_state <= WAIT;
    WAIT:
      if (read_bank_ready_to_switch && write_bank_ready_to_switch)
        next_state <= SWITCH;
      else
        next_state <= WAIT;
    SWITCH:
      if (is_last_write_bank)
        next_state <= START_R;
      else
        next_state <= START_RW;
    START_RW:
      next_state <= WAIT;
    START_R:
      next_state <= ENDSTATE;
    ENDSTATE:
      next_state <= ENDSTATE;
  endcase
end


// operations for each states
always @ ( * ) begin
  casez (state)
    RESET:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b0;
        start_new_read_bank  <= 1'b0;
      end
    CONFIG:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b0;
        start_new_read_bank  <= 1'b0;
      end
    START_W:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b1;
        start_new_read_bank  <= 1'b0;
      end
    WAIT:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b0;
        start_new_read_bank  <= 1'b0;
      end
    SWITCH:
      begin
        ready_to_switch      <= 1'b1;
        start_new_write_bank <= 1'b0;
        start_new_read_bank  <= 1'b0;
      end
    START_RW:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b1;
        start_new_read_bank  <= 1'b1;
      end
    START_R:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b0;
        start_new_read_bank  <= 1'b1;
      end
    ENDSTATE:
      begin
        ready_to_switch      <= 1'b0;
        start_new_write_bank <= 1'b0;
        start_new_read_bank  <= 1'b0;
      end
  endcase
end



endmodule
