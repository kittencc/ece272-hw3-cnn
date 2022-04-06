// write all  banks and then read all banks
// for IC0 = 2, IC1*IY0*IX0 = 4, OY1*OX1 = 2 (total # of banks)
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-02


module simple_main_controller_tb;

localparam IC0 = 2;
localparam COUNTER_WID = 8;             // needs to be large enough to save IC1*IX0*IY0
localparam CONFIG_WIDTH = 32;
localparam BANK_ADDR_WIDTH = 32;
localparam BUFFER_MEM_DEPTH = 256;     // capacity of the memory, larger than IC1*Ix0*IY0
localparam OY1_OX1 = 2;        // used for the write_bank_counter

localparam max_data_idx = OY1_OX1 * 4 * IC0;

// local signals begin
logic        clk;
logic        rst_n;

  // for ifmap_chaining
logic [15:0] input_dat;
logic        input_vld;
logic       input_rdy;

// for write_addr_gen
logic [CONFIG_WIDTH - 1 : 0] config_data;     // IC1_IY0_IX0 = 4, each bank contains 4 data chained over Ic0 = 2
// local signals end




// connect DUT
simple_main_controller
# (
  .IC0(IC0),
  .COUNTER_WID(COUNTER_WID),             
  .CONFIG_WIDTH(CONFIG_WIDTH),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),
  .BUFFER_MEM_DEPTH(BUFFER_MEM_DEPTH),     
  .OY1_OX1(OY1_OX1)        
)  main_controller_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .input_dat(input_dat),
  .input_vld(input_vld),
  .input_rdy(input_rdy),
  .config_data(config_data)
);




// clk
always #10 clk = ~clk;  // clk cycle is 20



// feed control signals and input data
initial begin

  integer windex = 0;

  clk <= 0;
  rst_n <= 0;
  
  #20 // next is config
  rst_n <= 1;
  config_data <= 0;
  input_dat <= 0;
  input_vld <= 0;

  #20 // config
  rst_n <= 1;
  config_data <= 4;
  input_dat <= 0;
  input_vld <= 0;

  // feed ifmap data
  while( windex < max_data_idx ) begin
    #20 
    rst_n <= 1;
    config_data <= 0;
    input_dat <= windex;
    input_vld <= 1;
    
    if (input_rdy)     // writing data this cycle
      windex = windex + 1;
  end


  #20 // complete here
  rst_n <= 1;
  config_data <= 0;
  input_dat <= 0;
  input_vld <= 0;


end



// config vcd display
  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, simple_main_controller_tb);
    #20000000;
    $finish(2);
  end

endmodule

