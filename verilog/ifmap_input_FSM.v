// The FSM that controls ifmap input_chaining, 
// ifmap_write_addr_gen, and ifmap_double_buffer modules
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-12-28
// updated on: 2021-12-30


module ifmap_input_FSM(
  input logic clk,
  input logic rst_n,
  input logic chaining_last_one,     // the input chaining module is chaining the last data (ready at the output next cycle)
  input logic writing_last_data,     // writing the last data in the bank to the double buffer this cycle
  input logic ready_to_switch,       // ready to switch the double buffer
  input logic start_new_write_bank,

  output logic config_enable,
  output logic en_input_chaining,
  output logic rst_n_chaining,   
  output logic switch               // for the double buffer
);

// local parameters
localparam RESET            = 3'b000; 
localparam CONFIG           = 3'b001; 
localparam INPUT_CHAINING   = 3'b010;
localparam RESET_CHAINING   = 3'b011;
localparam WRITE_BANK_COUNT = 3'b100;
localparam SWITCH           = 3'b101;
localparam WAIT1            = 3'b110;
localparam WAIT2            = 3'b111;



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
      next_state <= INPUT_CHAINING;
    INPUT_CHAINING:
      if (chaining_last_one)
        next_state <= RESET_CHAINING;
      else
        next_state <= INPUT_CHAINING;
    RESET_CHAINING:
      if (writing_last_data)
        next_state <= WRITE_BANK_COUNT;
      else
        next_state <= INPUT_CHAINING;
    WRITE_BANK_COUNT:
      next_state <= WAIT1;
    WAIT1:
      if (ready_to_switch)
        next_state <= SWITCH;
      else
        next_state <= WAIT1;
    SWITCH:
      if (start_new_write_bank)
        next_state <= INPUT_CHAINING;
      else
        next_state <= WAIT2;
    WAIT2:
      if (start_new_write_bank)
        next_state <= INPUT_CHAINING;
      else
        next_state <= WAIT2;
    default:
      next_state <= RESET;      // should never happen
  endcase
end



// operations for each states
always @ ( * ) begin
  casez (state)
    RESET:
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b0;
      end
    CONFIG: 
      begin
        config_enable       <= 1'b1;       // goes high
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b1;
      end
    INPUT_CHAINING:
      begin
        config_enable       <= 1'b0;       // goes low
        en_input_chaining   <= 1'b1;      // goes high
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b1;
      end
    RESET_CHAINING:       // no need for change
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b0;
      end
    WRITE_BANK_COUNT:
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b1;
     end
    SWITCH:
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b1;     // goes high
        rst_n_chaining      <= 1'b1;
      end
    WAIT1:                 // no need for change
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b1;
     end
    WAIT2:                 // no need for change
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        rst_n_chaining      <= 1'b1;
     end
   endcase
end




endmodule
