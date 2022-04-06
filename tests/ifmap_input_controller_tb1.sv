// IC0 = 2
// IC1 x Ix0 x IY0 = 2 * 2 * 2 = 8
// For this test bench, the read order is the same as the write order
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-12-30
// update on: 2021-12-31

//`include "/verilog/custom_types.sv"

module ifmap_input_controller_tb1;

localparam IC0 = 2;
localparam COUNTER_WID = 8;             // needs to be large enough to save IC1*IX0*IY0
localparam CONFIG_WIDTH = 32;
localparam BANK_ADDR_WIDTH = 32;
localparam BUFFER_MEM_DEPTH = 256;     // capacity of the memory, larger than IC1*Ix0*IY0
localparam OY1_OX1 = 2;        // used for the write_bank_counter


// local signals begin
// for input controller
logic        clk;
logic        rst_n;

  // for ifmap_chaining
logic [15:0] input_dat;
logic        input_vld;
logic       input_rdy;

// for write_addr_gen
logic [CONFIG_WIDTH - 1 : 0] config_data;
// for the ifmap_double_buffer
logic ren;
logic [BANK_ADDR_WIDTH - 1 : 0] raddr;
logic [16*IC0 - 1 : 0] rdata;

// for the controller FSM
logic ready_to_switch;
logic write_bank_ready_to_switch;
logic start_new_write_bank;
//logic one_write_bank_done;
logic [COUNTER_WID - 1 : 0] write_bank_count;


// for read addr gen
logic reading_last_data;
logic config_enable;
// local signals end




// clk
always #10 clk = ~clk;  // clk cycle is 20




// wire-up the DUT
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





// write-up the read address generation
// in this particular tb, we are using the same read order as write
input_write_addr_gen 
#( 
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH)
)
input_write_addr_gen_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .addr_enable(ren),
  .config_enable(config_enable),
  .config_data(config_data),
  .addr(raddr),
  .writing_last_data(reading_last_data)
);



// after reset, we can start reading ifmap data from the double buffer in
// 1 + IC0 + 3 = 6 cycles

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



// config vcd display
  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, ifmap_input_controller_tb1);
    #20000000;
    $finish(2);
  end


endmodule
