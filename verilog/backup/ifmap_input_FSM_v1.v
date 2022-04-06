// The FSM that controls ifmap input_chaining, 
// ifmap_write_addr_gen, and ifmap_double_buffer modules
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-12-28
// updated on: 2021-12-30


module ifmap_input_FSM(
  input logic clk,
  input logic rst_n,
  input logic chaining_done,
  input logic one_write_bank_done,
  input logic start_new_write_bank,

  output logic config_enable,
  output logic en_input_chaining,
  output logic switch,               // for the double buffer
  output logic en_write_bank_count,     // count # of write banks that were completed
  output ifmap_input_state_t state
);

// local signals
ifmap_input_state_t next_state;


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
      if (chaining_done)
        next_state <= RESET_CHAINING;
      else
        next_state <= INPUT_CHAINING;
    RESET_CHAINING:
      if (one_write_bank_done)
        next_state <= WRITE_BANK_COUNT;
      else
        next_state <= INPUT_CHAINING;
    WRITE_BANK_COUNT:
      next_state <= SWITCH;
    SWITCH:
      if (start_new_write_bank)
        next_state <= INPUT_CHAINING;
      else
        next_state <= WAIT;
    WAIT:
      if (start_new_write_bank)
        next_state <= INPUT_CHAINING;
      else
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
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        en_write_bank_count <= 1'b0; 
      end
    CONFIG: 
      begin
        config_enable       <= 1'b1;       // goes high
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        en_write_bank_count <= 1'b0;  
      end
    INPUT_CHAINING:
      begin
        config_enable       <= 1'b0;       // goes low
        en_input_chaining   <= 1'b1;      // goes high
        switch              <= 1'b0;    
        en_write_bank_count <= 1'b0; 
      end
    RESET_CHAINING:       // no need for change
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        en_write_bank_count <= 1'b0; 
      end
    WRITE_BANK_COUNT:
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        en_write_bank_count <= 1'b1;        // increment write_bank counter
      end
    SWITCH:
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b1;     // goes high
        en_write_bank_count <= 1'b0; 
      end
    WAIT:                 // no need for change
      begin
        config_enable       <= 1'b0;
        en_input_chaining   <= 1'b0;
        switch              <= 1'b0;    
        en_write_bank_count <= 1'b0;
      end
    endcase
end




endmodule
