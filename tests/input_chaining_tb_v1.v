// description: test bench for the input chaining module
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-07

`define IC0 4

module input_chaining_tb;

// local signals
logic [15:0] ifmap_dat;
logic        ifmap_vld;
logic        clk;
logic        rst_n;
logic        en_input;

logic [16*`IC0-1:0] ifmap_dat_chained;
logic              done;
logic              ifmap_rdy;



// clk
always #10 clk = ~clk;  // clk cycle is 20


// wire up the dut
input_chaining #(.IC0(`IC0)) chain_inst
(
  .ifmap_dat(ifmap_dat),
  .ifmap_vld(ifmap_vld),
  .clk(clk),
  .rst_n(rst_n),
  .en_input(en_input),

  .ifmap_dat_chained(ifmap_dat_chained),
  .done(done),
  .ifmap_rdy(ifmap_rdy)
);


initial begin

  clk <= 0;
  rst_n <= 0;
  
  #20 // sets control signals during neg cycle of clk
  rst_n <= 1;
  en_input <= 1;
  ifmap_vld <= 0;
  
  #20 // ifmap_vld not ready
  ifmap_vld <=0;
  
  #20 // data 0 appears at input
  ifmap_dat <= 1;
  ifmap_vld <= 1;
  
  #20 //data 1 not ready
  ifmap_vld <= 0;
  
  #20  // data1 ready
  ifmap_dat <= 2;
  ifmap_vld <= 1;
  
  #20 // data2 ready
  ifmap_dat <= 3;
  ifmap_vld <= 1;
  
  #20 // data 3 ready
  ifmap_dat <= 4;
  ifmap_vld <= 1;
  
  
  #20 // disable
  en_input <= 0;


end


initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, input_chaining_tb);
    #20000000;
    $finish(2);
  end



endmodule
