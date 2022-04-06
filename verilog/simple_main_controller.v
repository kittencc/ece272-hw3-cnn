// Author: Cheryl (Yingqiu) Cao
// Date: 2021-01-02
// contains ifmap_input_controller, simple_read_controller,
// simple_main_FSM


module simple_main_controller
# (
  parameter IC0 = 2,
  parameter COUNTER_WID = 8,             // needs to be large enough to save IC1*IX0*IY0
  parameter CONFIG_WIDTH = 32,
  parameter BANK_ADDR_WIDTH = 32,
  parameter BUFFER_MEM_DEPTH = 256,     // capacity of the memory, larger than IC1*Ix0*IY0
  parameter OY1_OX1 = 2*4        // used for the write_bank_counter
)
(
  input logic        clk,
  input logic        rst_n,

  // for ifmap_chaining
  input logic [15:0] input_dat,
  input logic        input_vld,
  output logic       input_rdy,

// for write_addr_gen
  input logic [CONFIG_WIDTH - 1 : 0] config_data

);



// local signals begin
// for the ifmap_double_buffer
logic ren;
logic [BANK_ADDR_WIDTH - 1 : 0] raddr;
logic [16*IC0 - 1 : 0] rdata;

// for the FSMs
logic ready_to_switch;                   // from main FSM
logic start_new_read_bank; 
logic start_new_write_bank;              // from main FSM

logic read_bank_ready_to_switch;
logic write_bank_ready_to_switch;       // to main_FSM
logic is_last_read_bank;
logic is_last_write_bank;


// for the counters
logic [COUNTER_WID - 1 : 0] write_bank_count;
logic [COUNTER_WID - 1 : 0] read_bank_count;     // # of banks that completed reading
// local signals end




// logic for is_last_read/write_bank
assign is_last_read_bank = (read_bank_count == OY1_OX1);
assign is_last_write_bank = (write_bank_count == OY1_OX1);




// connect ifmap_input_controller
ifmap_input_controller 
# (
  .IC0(IC0),
  .COUNTER_WID(COUNTER_WID),
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),
  .BUFFER_MEM_DEPTH(BUFFER_MEM_DEPTH),
  .OY1_OX1(OY1_OX1)
) ifmap_input_controller_inst
(
  .clk(clk),
  .rst_n(rst_n),

  // for ifmap_chaining
  .input_dat(input_dat),
  .input_vld(input_vld),
  .input_rdy(input_rdy),

// for write_addr_gen
  .config_data(config_data),
// for the ifmap_double_buffer
  .ren(ren),
  .raddr(raddr),
  .rdata(rdata),


  // for the controller FSM
  .ready_to_switch(ready_to_switch),
  .start_new_write_bank(start_new_write_bank),
  .write_bank_ready_to_switch(write_bank_ready_to_switch),
  .write_bank_count(write_bank_count)

);




// connect simple_read_controller
simple_read_controller
# (
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),
  .COUNTER_WID(COUNTER_WID),             
  .OY1_OX1(OY1_OX1)       
) read_controller_inst
(
  .clk(clk),
  .rst_n(rst_n),

  // for read_addr_gen
  .config_data(config_data),
 
  // for the read FSM
  .start_new_read_bank(start_new_read_bank),
  .read_bank_ready_to_switch(read_bank_ready_to_switch),
  .read_bank_count(read_bank_count),
  .ren(ren),
  .raddr(raddr)

);



// connect simple_main_FSM
simple_main_FSM main_FSM_inst (
  .clk(clk),
  .rst_n(rst_n),
  .read_bank_ready_to_switch(read_bank_ready_to_switch),
  .write_bank_ready_to_switch(write_bank_ready_to_switch),
  .is_last_read_bank(is_last_read_bank),
  .is_last_write_bank(is_last_write_bank),
  .start_new_read_bank(start_new_read_bank),
  .start_new_write_bank(start_new_write_bank),
  .ready_to_switch(ready_to_switch)
);




endmodule
