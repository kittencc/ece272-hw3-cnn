// Description: testbench 1
// OY0_OX0 = 2*2 = 4
// OC0 = 2 for unchaining
// run for one ofmap read bank
// 1. write data 1_2, 3_4, 5_6, 7_8 to accum_double_buffer
// 2. switch
// 3. let ofmap_output_controller run to read ofmap data out and unchain
// them
//   - monitor ofmap_data, we should get 2, 1, 4, ... , 8, 7
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-03-13
// Updated on: 2020-05-07: change port connections

module ofmap_output_controller_tb1;

localparam OC0 = 2;
localparam BANK_ADDR_WIDTH = 32;       // width of read/write addr
localparam MEM_DEPTH       = 256;     // depth of the accum_double_buffer, larger than OY0 * OX0 = 9
// localparam OY1_OX1_OC1 = 2*2*2;       // used for the ofmap_read_bank_counter


// local signals ++
  logic clk;
  logic rst_n;

  // for ofmap_PISO
  logic ofmap_rdy;
  logic [31 : 0] ofmap_dat;
  logic ofmap_vld;

  // for accum_double_buffer
  // 1 read 1 write ports for the mac array and the accum sum 
  logic wen;
  logic [BANK_ADDR_WIDTH - 1 : 0] waddr;
  logic [32*OC0 - 1 : 0] wdata;
  logic ren;
  logic [BANK_ADDR_WIDTH - 1 : 0] raddr_accum;
  logic [32*OC0 - 1 : 0] rdata_accum;

  // for the config parameters
  logic [BANK_ADDR_WIDTH - 1 : 0] config_OY0_OX0;   // for ofmap_read_addr_gen
  logic [BANK_ADDR_WIDTH - 1 : 0] config_OY1_OX1_OC1;   // for read bank counter


  // for the main FSM
  logic config_done;     // from the top FSM
  logic ready_to_switch;
  logic start_new_read_bank;
  logic read_bank_ready_to_switch;
  logic [BANK_ADDR_WIDTH - 1 : 0] ofmap_read_bank_count;     // the # of ofmap read bank that was completed, up to OY1_OX1_OC1
// local signals --





// clk
always #10 clk = ~clk;  // clk cycle is 20



// connect dut
ofmap_output_controller
# (
  .OC0(OC0),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),       // width of read/write addr
  .MEM_DEPTH(MEM_DEPTH)     // depth of the accum_double_buffer, larger than OY0 * OX0 = 9
)
dut
(
  .clk(clk),
  .rst_n(rst_n),
  .ofmap_rdy(ofmap_rdy),
  .ofmap_dat(ofmap_dat),
  .ofmap_vld(ofmap_vld),
  .wen(wen),
  .waddr(waddr),
  .wdata(wdata),
  .ren(ren),
  .raddr_accum(raddr_accum),
  .rdata_accum(rdata_accum),
  .config_OY0_OX0(config_OY0_OX0),
  .config_OY1_OX1_OC1(config_OY1_OX1_OC1),
  .config_done(config_done),
  .ready_to_switch(ready_to_switch),
  .start_new_read_bank(start_new_read_bank),
  .read_bank_ready_to_switch(read_bank_ready_to_switch),
  .ofmap_read_bank_count(ofmap_read_bank_count)     // the # of ofmap read bank that was completed, up to OY1_OX1_OC1
);


initial begin

  integer windex, rindex;

  clk <= 0;
  rst_n <= 0;
  
  #20 // next is config
  rst_n       = 1;

  config_OY1_OX1_OC1 = 8;       // OY0_OX0
  config_OY0_OX0     = 4;
  config_done        = 0;

  ofmap_rdy   = 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   = 0;
  wdata = 0;
  waddr = 0;
  // main FSM control
  ready_to_switch     = 0;
  start_new_read_bank = 0;
 
 #20 // config
  rst_n       <= 1;
  
  config_OY1_OX1_OC1 = 8;       // OY0_OX0
  config_OY0_OX0     = 4;
  config_done        = 1;
 
  ofmap_rdy   <= 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 0;
  start_new_read_bank <= 0;


  // write data 1_2, 3_4, 5_6, 7_8 to accum_double_buffer
  // ofmap data width is 32 bit
  for (windex = 0; windex < 4; windex = windex + 1) begin
    #20 // wait for 1 cycle
    rst_n       <= 1;
    ofmap_rdy   <= 0;        // tb ready to receive ofmap data
    // for accum double buffer
    wen   <= 1;
    wdata <= {32'(2*windex+1), 32'(2*windex+2)};    // concatenation of 2 32-bit long numbers
    waddr <= windex;
    // main FSM control
    ready_to_switch     <= 0;
    start_new_read_bank <= 0;

    config_done        = 0;
 
  end


 #20 // next is switch
  rst_n       <= 1;
  ofmap_rdy   <= 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 1;
  start_new_read_bank <= 0;


  #20 // switch, next is read_double_buffer
  rst_n       <= 1;
  ofmap_rdy   <= 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 0;
  start_new_read_bank <= 1;


 #20 // read_double_buffer
  rst_n       <= 1;
  ofmap_rdy   <= 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 0;
  start_new_read_bank <= 0;

 #20 // load
  rst_n       <= 1;
  ofmap_rdy   <= 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 0;
  start_new_read_bank <= 0;

  #20 // start_PISO, assume ofmap is not ready
  rst_n       <= 1;
  ofmap_rdy   <= 0;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 0;
  start_new_read_bank <= 0;

 #20 // start_PISO
  rst_n       <= 1;
  ofmap_rdy   <= 1;        // tb ready to receive ofmap data
  // for accum double buffer
  wen   <= 0;
  wdata <= 0;
  waddr <= 0;
  // main FSM control
  ready_to_switch     <= 0;
  start_new_read_bank <= 0;

 // PISO, would take at least OY0_OX0* OC0 = 8 CYCLES HERE
 // 20 * 4* 10
 #800;


end


/* 
// config vcd display
  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, ofmap_output_controller_tb1);
    #20000000;
    $finish(2);
  end
*/


// dumping fsdb waveform for Verdi
initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, ofmap_output_controller_tb1);
  $fsdbDumpMDA(0, ofmap_output_controller_tb1);
  #10000;
  $finish;
end


endmodule
