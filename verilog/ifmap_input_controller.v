// controller for ifmap input
// connect ifmap_chaining, double_buffer, input_write_addr_gen, and FSM together.
// Author: Cheryl (Yingqiu) Cao
// Date:: 2021-12-28
// updated on: 2022-01-06
// updated on: 2022-04-30 : "counter" module related changes
// updated on: 2022-05-01: changed "config" state for the FSM.


module ifmap_input_controller
# (
  parameter IC0 = 4,
  parameter BANK_ADDR_WIDTH = 16,        // width needed to save IC1*IX0*IY0, OY1_OX1
  parameter BUFFER_MEM_DEPTH = 256     // capacity of the memory, larger than IC1*Ix0*IY0
)
(
  input logic        clk,
  input logic        rst_n,

  // for ifmap_chaining
  input logic [15:0] input_dat,
  input logic        input_vld,
  output logic       input_rdy,

  // for the config parameters
  input logic [BANK_ADDR_WIDTH - 1 : 0] config_IC1_IY0_IX0,
  input logic [BANK_ADDR_WIDTH - 1 : 0] config_OY1_OX1,


// for the ifmap_double_buffer
  input logic ren,
  input logic [BANK_ADDR_WIDTH - 1 : 0] raddr,
  output logic [16*IC0 - 1 : 0] rdata,

// for the controller FSM
  input logic ready_to_switch,                   // from main FSM
  input logic start_new_write_bank,              // from main FSM
  input logic config_done,           // flag from the top module

//  output logic one_write_bank_done
  output logic write_bank_ready_to_switch,       // to main_FSM
  output logic [BANK_ADDR_WIDTH - 1 : 0] write_bank_count

);


// local signals begin
// for ifmap_chaining
logic              this_rst_n;          // reset signal for the chaining module
logic              rst_n_chaining;      // from the FSM
logic              en_input_chaining;   // en for the chaining module
logic [16*IC0-1:0] input_dat_chained;
logic              chaining_last_one;   // chaining output ready next cycle
logic              chaining_done;       // chaining done is chaining_last_one delayed by 1 clk cycle

// for write_addr_gen
logic                           addr_enable;
logic                           config_enable;
logic [BANK_ADDR_WIDTH - 1 : 0] waddr;
logic                           writing_last_data;      // writing the last data in the bank to the double buffer this cycle (done next cycle)

// for the ifmap_double_buffer
logic switch;
logic wen;
logic [16*IC0-1 : 0] wdata;

// for the FSM
logic one_write_bank_done;                // goes high when we finish writing a whole bank's ifmap data to the double buffer
logic en_write_bank_count;                // control signal to enable the write_bank counter

// local signals end



assign addr_enable = chaining_done;
assign wen = chaining_done;
assign wdata = input_dat_chained;
assign this_rst_n = rst_n && rst_n_chaining;        // we can reset only the chaining module but not others by rst_n_chaining





// logic for one_write_bank_done
//  this flag only stays high for 1 clk cycle
always @ ( posedge clk ) begin
  if ( !rst_n || start_new_write_bank )
    one_write_bank_done <= 1'b0;
  else                  // goes to high after the last ifmap data gets written to the double buffer
    one_write_bank_done <= writing_last_data;
end


// logic for write_bank_ready_to_switch
// this signal goes high after one_write_bank_done
// it stays high during wait/switch states
always @ ( posedge clk ) begin
  if ( !rst_n || switch )
    write_bank_ready_to_switch <= 1'b0;
  else if (one_write_bank_done)
    write_bank_ready_to_switch <= 1'b1;
end




// connect write_bank counter
// tracks the curremt # of write banks that were completed
//  counts from 0 to (MAX_COUNT - 1)
counter
#(
  .COUNTER_WID(BANK_ADDR_WIDTH)
)
write_bank_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(one_write_bank_done),
  .count(write_bank_count),
  .config_MAX_COUNT(config_OY1_OX1+1)
);



// connect ifmap_chaining module
input_chaining
#(
 .IC0(IC0),
 .COUNTER_WID(BANK_ADDR_WIDTH)
)
input_chaining_inst
(
  .input_dat(input_dat),
  .input_vld(input_vld),
  .clk(clk),
  .rst_n(this_rst_n),
  .en_input(en_input_chaining),
  .input_dat_chained(input_dat_chained),
  .chaining_last_one(chaining_last_one),
  .done(chaining_done),
  .input_rdy(input_rdy)
);


// connect input_write_addr_gen module
input_write_addr_gen
#(
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
input_write_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(addr_enable),
  .config_data(config_IC1_IY0_IX0),
  .addr(waddr),
  .writing_last_data(writing_last_data)
);



// connect  ifmap_double_buffer module
double_buffer
#(
  .DATA_WIDTH(16*IC0),     // original data width 16 * chaining_length of 4
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),       // width of read/write addr
  .MEM_DEPTH(BUFFER_MEM_DEPTH)     // capacity of the memory
)
ifmap_double_buffer_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .switch_banks(switch),
  .ren(ren),
  .radr(raddr),
  .rdata(rdata),
  .wen(wen),
  .wadr(waddr),
  .wdata(wdata)
);



// connect ifmap_input_FSM module
ifmap_input_FSM ifmap_input_FSM_inst (
  .clk(clk),
  .rst_n(rst_n),
  .chaining_last_one(chaining_last_one),
  .writing_last_data(writing_last_data),
  .ready_to_switch(ready_to_switch),
  .start_new_write_bank(start_new_write_bank),
  .config_done(config_done),

  .en_input_chaining(en_input_chaining),
  .rst_n_chaining(rst_n_chaining),
  .switch(switch)               // for the double buffer
);




endmodule
