// controller for ifmap input
// connect ifmap_chaining, double_buffer, input_write_addr_gen, and FSM together.  
// Author: Cheryl (Yingqiu) Cao
// Date:: 2021-12-28
// updated on: 2021-12-30


module ifmap_input_controller
# (
  parameter IC0 = 4,
  parameter COUNTER_WID = 8,             // needs to be large enough to save IC1*IX0*IY0
  parameter CONFIG_WIDTH = 32,
  parameter BANK_ADDR_WIDTH = 32,
  parameter BUFFER_MEM_DEPTH = 256,     // capacity of the memory, larger than IC1*Ix0*IY0
  parameter IC1_IX0_IY0 = 4*5*5        // used for the write_bank_counter
)
(
  input logic        clk,
  input logic        rst_n,

  // for ifmap_chaining
  input logic [15:0] input_dat,
  input logic        input_vld,
  output logic       input_rdy,

// for write_addr_gen
  input logic [CONFIG_WIDTH - 1 : 0] config_data,
// for the ifmap_double_buffer
  input logic ren,
  input logic [BANK_ADDR_WIDTH - 1 : 0] raddr,
  output logic [16*IC0 - 1 : 0] rdata,

// for the controller FSM
  input logic start_new_write_bank,
  output logic one_write_bank_done,
  output logic [COUNTER_WID - 1 : 0] write_bank_count

);


// local signals begin
// for ifmap_chaining
logic              this_rst_n;          // reset signal for the chaining module
logic              rst_n_chaining;      // from the FSM
logic              en_input_chaining;   // en for the chaining module
logic [16*IC0-1:0] input_dat_chained;
logic              chaining_done;

// for write_addr_gen
logic                           addr_enable;
logic                           config_enable;
logic [BANK_ADDR_WIDTH - 1 : 0] waddr;
logic                           last_input_write_addr;      // if the current waddr is the last one of the bank

// for the ifmap_double_buffer
logic switch;
logic wen;
logic [16*IC0-1 : 0] wdata;

// for the FSM
logic one_write_bank_done;                // goes high when we finish writing a whole bank's ifmap data to the double buffer
logic en_write_bank_count;                // control signal to enable the write_bank counter
ifmap_input_state_t state;                // state of the FSM

// for the config parameters
logic [BANK_ADDR_WIDTH - 1 : 0] config_IC1_IY0_IX0;

// local signals end        



assign addr_enable = chaining_done;
assign wen = chaining_done;
assign wdata = input_dat_chained;
assign this_rst_n = rst_n && rst_n_chaining;        // we can reset only the chaining module but not others by rst_n_chaining
assign rst_n_chaining = ~chaining_done;             // need to reset the SIPO each word




// logic for one_write_bank_done
always @ ( posedge clk ) begin
  if ( !rst_n || start_new_write_bank )
    one_write_bank_done <= 1'b0;
  else                  // goes to high after the last ifmap data gets written to the double buffer
    one_write_bank_done <= last_input_write_addr && addr_enable;
end




// connect write_bank counter
// tracks the curremt # of write banks that were completed
counter  
#(
  .MAX_COUNT(IC1_IX0_IY0-1),
  .COUNTER_WID(COUNTER_WID)
)
write_bank_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(one_write_bank_done),
  .count(write_bank_count)
);



// connect ifmap_chaining module
input_chaining 
#(
 .IC0(IC0),
 .COUNTER_WID(COUNTER_WID)
)
input_chaining_inst
(
  .input_dat(input_dat),
  .input_vld(input_vld),
  .clk(clk),
  .rst_n(this_rst_n),
  .en_input(en_input_chaining),
  .input_dat_chained(input_dat_chained),
  .done(chaining_done),
  .input_rdy(input_rdy)
);


// connect input_write_addr_gen module
input_write_addr_gen 
#( 
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
) 
input_write_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(addr_enable),
  .config_enable(config_enable),
  .config_data(config_data),
  .addr(waddr),
  .last_input_write_addr(last_input_write_addr)
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
  .chaining_done(chaining_done),
  .one_write_bank_done(one_write_bank_done),
  .start_new_write_bank(start_new_write_bank),

  .config_enable(config_enable),
  .en_input_chaining(en_input_chaining),
  .switch(switch),               // for the double buffer
  .en_write_bank_count(en_write_bank_count),     // count # of write banks that were completed
  .state(state)
);




endmodule
