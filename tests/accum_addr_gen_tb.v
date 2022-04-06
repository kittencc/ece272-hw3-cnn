// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-06


module accum_addr_gen_tb;

localparam CONFIG_WIDTH = 32;
localparam BANK_ADDR_WIDTH = 8;

// local signals
logic clk;
logic rst_n;
logic config_enable;
logic [CONFIG_WIDTH - 1 : 0] config_data;
logic addr_enable;
logic [BANK_ADDR_WIDTH - 1 : 0] addr;
logic writing_last_data;

// clk generation
  always #10 clk =~clk;


// wire up the DUT
  accum_addr_gen #( 
    .CONFIG_WIDTH(32),
    .BANK_ADDR_WIDTH(8)
  ) addr_gen_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr_enable(addr_enable),
    .config_enable(config_enable),
    .config_data(config_data),
    .addr(addr),
    .writing_last_data(writing_last_data)
  );
 

  initial begin
    clk <= 0;
    rst_n <= 1;
    config_enable <= 0;
    config_data <= 0;
    addr_enable <= 0;
    #20 rst_n <= 0;

    #20 rst_n <= 1;
    config_enable <= 1;
    config_data <= 5*5; // For the example in the homework pdf, OY0 = 5, OX0 = 5

    #20 config_enable <= 0;
    addr_enable <= 1;
    assert(addr == 0);
    #15 assert(addr == 1);
    #20 assert(addr == 2);
    #20 assert(addr == 3);
    #20 assert(addr == 4);
    #400 assert(addr == 24); assert(writing_last_data);
    #20 assert(addr == 0);
    addr_enable <= 0;
    #20 assert(addr == 0);
    addr_enable <= 1;
    #20 assert(addr == 1);
  end
  
  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, accum_addr_gen_tb);
    #20000000;
    $finish(2);
  end





endmodule
