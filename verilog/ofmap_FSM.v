// Description: the FSM that controlls ofmap readout from the
// accum_double_buffer module. The ofmap output data gets sent to the
// testbench
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-03-12

module ofmap_FSM
(
  input logic clk,
  input logic rst_n,

  // for the read_addr_gen 
  input logic last_ofmap_data,     // the unchained data in the last one in this ofmap bank
  output logic config_enable,
  output logic raddr_gen_en,

  // for accum_double_buffer
  output logic ren,
  output logic switch,

  // for ofmap unchaining PISO
  input logic unchaining_last_one,
  input logic ready_to_unchain,
  output logic en_PISO,
  output logic load,
  output logic start,

  // for the ofmap read bank counter
  output logic one_read_bank_done,   // en signal for the counter

  // for the main FSM
  input logic ready_to_switch,
  input logic start_new_read_bank,
  output logic read_bank_ready_to_switch
  
);

// local parameters
localparam RESET            = 4'b0000; 
localparam CONFIG           = 4'b0001; 
localparam WAIT1            = 4'b0010;
localparam SWITCH           = 4'b0011;
localparam WAIT2            = 4'b0100;
localparam READ_DOUBLE_BUF  = 4'b0101;
localparam LOAD_STATE       = 4'b0110;
localparam START_PISO       = 4'b0111;
localparam PISO             = 4'b1000;
localparam READ_BANK_COUNT  = 4'b1001;


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
      if (rst_n)    // not reset
        next_state <= CONFIG;
      else
        next_state <= RESET;
    CONFIG:
      next_state <= WAIT1;
    READ_DOUBLE_BUF:
      next_state <= LOAD_STATE;
    LOAD_STATE:
      next_state <= START_PISO;
    START_PISO:
      if (ready_to_unchain)
        next_state <= PISO;
      else
        next_state <= START_PISO;
    PISO:
      if (!unchaining_last_one)
        next_state <= PISO;
      else if (!last_ofmap_data)
        next_state <= READ_DOUBLE_BUF;
      else
        next_state <= READ_BANK_COUNT;
    READ_BANK_COUNT:
      next_state <= WAIT1;
    WAIT1:
      if (ready_to_switch)
        next_state <= SWITCH;
      else
        next_state <= WAIT1;
    SWITCH:
      if (start_new_read_bank)
        next_state <= READ_DOUBLE_BUF;
      else
        next_state <= WAIT2;
    WAIT2:
      if (start_new_read_bank)
        next_state <= READ_DOUBLE_BUF;
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
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    CONFIG:
     begin
        config_enable             <= 1'b1;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
     end
    READ_DOUBLE_BUF:
     begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b1;
        ren                       <= 1'b1;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
     end
    LOAD_STATE:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b1;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    START_PISO:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b1;
        load                      <= 1'b0;
        start                     <= 1'b1;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    PISO:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b1;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    READ_BANK_COUNT:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b1;
        read_bank_ready_to_switch <= 1'b0;
      end
    WAIT1:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b1;
      end
    SWITCH:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b1;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
    WAIT2:
       begin
        config_enable             <= 1'b0;
        raddr_gen_en              <= 1'b0;
        ren                       <= 1'b0;
        switch                    <= 1'b0;
        en_PISO                   <= 1'b0;
        load                      <= 1'b0;
        start                     <= 1'b0;
        one_read_bank_done        <= 1'b0;
        read_bank_ready_to_switch <= 1'b0;
      end
   endcase
end




endmodule
