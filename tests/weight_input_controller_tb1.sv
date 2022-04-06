// test bench for weight_input_controller
//  OC0 = 2 for data chaining
// OC1*IC1 x FY x Fx x IC0 = 1* 2 * 2 * 2 = 8
// For this test bench, the read order is the same as the write order
// Description: - writes 2_1, 4_3, .... 16_15 to the weight double buffer
//              - switch the buffers
//              - read the weight data out in the same order
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-2


module weight_input_controller_tb1;

// local parameters
  localparam OC0 = 2;
  localparam COUNTER_WID = 16;            // needs to be large enough to save OC1*IC1*FY*FX*IC0
  localparam CONFIG_WIDTH = 32;
  localparam BANK_ADDR_WIDTH = 32;
  localparam BUFFER_MEM_DEPTH = 256;     // capacity of the memory, larger than IC1*Ix0*IY0
  localparam WRITE_BANK_NUM = 1;       // used for the write_bank_counter, the number of weight banks we need to write to,  one

// local signals ++
  logic        clk;
  logic        rst_n;

  // for weight_chaining
  logic [15:0] input_dat;
  logic        input_vld;
  logic       input_rdy;

// for write_addr_gen
  logic [CONFIG_WIDTH - 1 : 0] config_data;
// for the weight_double_buffer
  logic ren;
  logic [BANK_ADDR_WIDTH - 1 : 0] raddr;
  logic [16*OC0 - 1 : 0] rdata;

// for the controller FSM
  logic ready_to_switch;                   // from main FSM
  logic start_new_write_bank;              // from main FS;

//  output logic one_write_bank_done,             
  logic write_bank_ready_to_switch;       // to main_FS;
  logic [COUNTER_WID - 1 : 0] write_bank_count;

// for weight_read_addr_gen
  logic config_enable;
  logic reading_last_data;
// local signals --



// clk
always #10 clk = ~clk;  // clk cycle is 20




// wire-up the DUT
weight_input_controller
# (
  .OC0(OC0),
  .COUNTER_WID(COUNTER_WID),             // needs to be large enough to save OC1*IC1*FY*FX*IC0
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),
  .BUFFER_MEM_DEPTH(BUFFER_MEM_DEPTH),     // capacity of the memory, larger than IC1*Ix0*IY0
  .WRITE_BANK_NUM(WRITE_BANK_NUM)       // used for the write_bank_counter, the number of weight banks we need to write to,  one
) dut
(
  .clk(clk),
  .rst_n(rst_n),

  // for weight_chaining
  .input_dat(input_dat),
  .input_vld(input_vld),
  .input_rdy(input_rdy),

// for write_addr_gen
  .config_data(config_data),
// for the weight_double_buffer
  .ren(ren),
  .raddr(raddr),
  .rdata(rdata),

// for the controller FSM
  .ready_to_switch(ready_to_switch),                   // from main FSM
  .start_new_write_bank(start_new_write_bank),              // from main FSM

//  output logic one_write_bank_done,             
  .write_bank_ready_to_switch(write_bank_ready_to_switch),       // to main_FSM
  .write_bank_count(write_bank_count)

);



//wire up the read_addr_gen
weight_addr_gen
# (
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
) 
 weight_read_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(ren),
  .config_enable(config_enable),
  .config_data( config_data),
  .addr(raddr),
  .writing_last_data(reading_last_data)
);


initial begin

  integer windex, rindex;

  clk <= 0;
  rst_n <= 0;
  
  #20 // next is config
  rst_n <= 1;
  config_enable <= 0;
  config_data <= 8;
  input_dat <= 0;
  input_vld <= 0;
  ren <= 0;
  start_new_write_bank <= 0;
  ready_to_switch <= 0;

  #20 // config
  rst_n <= 1;
  config_enable <= 1;
  config_data <= 8;
  input_dat <= 0;
  input_vld <= 0;
  ren <= 0;
  start_new_write_bank <= 0;
  ready_to_switch <= 0;

  for (windex = 0; windex < 8; windex = windex + 1) begin
    #20 // chaining cycle 1
    rst_n <= 1;
    config_enable <= 0;
    config_data <= 0;
    input_dat <= windex*2 + 1;
    input_vld <= 1;
    ren <= 0;
    start_new_write_bank <= 0;
    ready_to_switch <= 0;

    #20 // chaining cycle 2
    rst_n <= 1;
    config_enable <= 0;
    config_data <= 0;
    input_dat <= windex*2 + 2;
    input_vld <= 1;
    ren <= 0;
    start_new_write_bank <= 0;
    ready_to_switch <= 0;

//    #20 // chaining done
//    rst_n <= 1;
//    config_enable <= 0;
//    config_data <= 0;
//    input_dat <= windex*2 + 3;
//    input_vld <= 1;
//    ren <= 0;
//    start_new_write_bank <= 0;

    #20 // reset_chaining, waddr = 0
    rst_n <= 1;
    config_enable <= 0;
    config_data <= 0;
    input_dat <= windex*2 + 3;
    input_vld <= 1;
    ren <= 0;
    start_new_write_bank <= 0;
    ready_to_switch <= 0;
 end


 #20 // write bank count
  rst_n <= 1;
  config_enable <= 0;
  config_data <= 8;
  input_dat <= 0;
  input_vld <= 0;
  ren <= 0;
  start_new_write_bank <= 0;
  ready_to_switch <= 0;

  #20 // wait
  rst_n <= 1;
  config_enable <= 0;
  config_data <= 0;
  input_dat <= 0;
  input_vld <= 0;
  ren <= 0;
  start_new_write_bank <= 0;
  ready_to_switch <= 1;       // make sure to switch next cycle

 #20 // switch
  rst_n <= 1;
  config_enable <= 0;
  config_data <= 0;
  input_dat <= 0;
  input_vld <= 0;
  ren <= 0;
  start_new_write_bank <= 0;
  ready_to_switch <= 0;

  // starts reading
  for (rindex = 0; rindex < 9; rindex = rindex + 1) begin
    #20 
    rst_n <= 1;
    config_enable <= 0;
    config_data <= 0;
    input_dat <= 0;
    input_vld <= 1;
    ren <= 1;
    start_new_write_bank <= 0;
    ready_to_switch <= 0;
 end

  // stops reading
  rst_n <= 1;
  config_enable <= 0;
  config_data <= 8;
  input_dat <= 0;
  input_vld <= 0;
  ren <= 0;
  start_new_write_bank <= 0;
  ready_to_switch <= 0;

end



// dumping fsdb waveform for Verdi
initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0);
  $fsdbDumpon;
  #1000000;
  $fsdbDumpoff;
  $finish(2);
end



endmodule
