// Description: controller to read ofmap data from accum_double_buffer
//              and send to the testbench.
//              Contains ofmap_PISO, accum_double_buffer,
//              ofmap_read_addr_gen, ofmap_FSM and read_bank_counter
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-03-13
// Updated on: 2022-03-18

module ofmap_output_controller
# (
  parameter OC0 = 4,
  parameter COUNTER_WID = 4,
  parameter CONFIG_WIDTH = 32,
  parameter BANK_ADDR_WIDTH = 32,       // width of read/write addr
  parameter MEM_DEPTH       = 256,     // depth of the accum_double_buffer, larger than OY0 * OX0 = 9
  parameter OY1_OX1_OC1 = 4*4*4       // used for the ofmap_read_bank_counter

)
(
  input logic clk,
  input logic rst_n,

  // for ofmap_PISO
  input logic ofmap_rdy,
  output logic [31 : 0] ofmap_dat,
  output logic ofmap_vld,

  // for accum_double_buffer
  // 1 read 1 write ports for the mac array and the accum sum 
  input logic wen,
  input logic [BANK_ADDR_WIDTH - 1 : 0] waddr,
  input logic [32*OC0 - 1 : 0] wdata,
  input logic ren,
  input logic [BANK_ADDR_WIDTH - 1 : 0] raddr_accum,
  output logic [32*OC0 - 1 : 0] rdata_accum,

  // for ofmap_read_addr_gen
  input logic [CONFIG_WIDTH - 1 : 0] config_data,

  // for the main FSM
  input logic ready_to_switch,
  input logic start_new_read_bank,
  output logic read_bank_ready_to_switch,
  output logic [COUNTER_WID - 1 : 0] ofmap_read_bank_count     // the # of ofmap read bank that was completed, up to OY1_OX1_OC1

);


// local signals ++
  // for ofmap_PISO
  logic en_PISO;
  logic load;        // load chained data into internal ffs
  logic start;       // sel signal for the shifter's input mux, loads chained data into the shifter 
  logic unchaining_last_one;          // output to the FSM
  logic [32*OC0 - 1 : 0] ofmap_dat_chained;

  // for accum_double_buffer
  logic  switch;       // trigger to switch read/write banks
 // 1 read port to send ofmap data out
  logic  ren_ofmap;
  logic [BANK_ADDR_WIDTH - 1 : 0] raddr_ofmap;
  logic [32*OC0 - 1 : 0] rdata_ofmap;

  // for ofmap_read_addr_gen
  logic raddr_gen_en;
  logic config_enable;
  logic reading_last_data;
  logic last_ofmap_data;          // the current ofmap data is the last one from the current read bank

  // for the ofmap read bank counter
  logic one_read_bank_done;   // en signal for the counter
// local signals --


// connecting local signals
assign ofmap_dat_chained = rdata_ofmap;


// logic for last_ofmap_data
always @(posedge clk) begin
  if (!rst_n || switch)
    last_ofmap_data <= 1'b0;
  else if (reading_last_data)
    last_ofmap_data <= 1'b1;
end


// connect ofmap read bank counter
// tracks the curremt # of write banks that were completed
//  counts from 0 to (MAX_COUNT - 1)
counter  
#(
  .MAX_COUNT(OY1_OX1_OC1+1),
  .COUNTER_WID(COUNTER_WID)
)
ofmap_read_bank_counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(one_read_bank_done),
  .count(ofmap_read_bank_count)
);



// connect ofmap_PISO
ofmap_PISO
# (
  .OC0(OC0),
  .COUNTER_WID(COUNTER_WID)
)
ofmap_PISO_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en_PISO(en_PISO),
  .load(load),        // load chained data into internal ffs
  .start(start),       // sel signal for the shifter's input mux, loads chained data into the shifter 
  .chaining_last_one(unchaining_last_one),          // output to the FSM
  .ofmap_dat_chained(ofmap_dat_chained),
  .ofmap_rdy(ofmap_rdy),
  .ofmap_dat(ofmap_dat),
  .ofmap_vld(ofmap_vld)
);




// connect accum_double_buffer
accum_double_buffer
#( 
  .DATA_WIDTH(32*OC0),     // original data width 32 * chaining_length of 4
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),       // width of read/write addr
  .MEM_DEPTH(MEM_DEPTH)     // capacity of the memory
)
accum_double_buffer_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .switch_banks(switch),
  .wen(wen),
  .waddr(waddr),
  .wdata(wdata),
  .ren(ren),
  .raddr_accum(raddr_accum),
  .rdata_accum(rdata_accum),
  .ren_ofmap(ren_ofmap),
  .raddr_ofmap(raddr_ofmap),
  .rdata_ofmap(rdata_ofmap)
);




// connect ofmap_read_addr_gen
accum_addr_gen
# (
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
ofmap_read_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(raddr_gen_en),
  .config_enable(config_enable),
  .config_data(config_data),
  .addr(raddr_ofmap),
  .writing_last_data(reading_last_data)
);




// connect ofmap_FSM
ofmap_FSM ofmap_FSM_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .last_ofmap_data(last_ofmap_data),     // the unchained data in the last one in this ofmap bank
  .config_enable(config_enable),
  .raddr_gen_en(raddr_gen_en),
  .ren(ren_ofmap),
  .switch(switch),
  .unchaining_last_one(unchaining_last_one),
  .ready_to_unchain(ofmap_rdy),
  .en_PISO(en_PISO),
  .load(load),
  .start(start),
  .one_read_bank_done(one_read_bank_done),   // en signal for the counter
  .ready_to_switch(ready_to_switch),
  .start_new_read_bank(start_new_read_bank),
  .read_bank_ready_to_switch(read_bank_ready_to_switch)
);



endmodule
