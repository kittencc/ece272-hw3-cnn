// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-13

module weights_chaining_tb;

localparam OC0 = 4;

// local signals
logic [15:0] weights_dat;
logic        weights_vld;
logic        clk;
logic        rst_n;
logic        en_input;

logic [16*OC0-1:0] weights_dat_chained;
logic              done;
logic              weights_rd;


// clk
always #10 clk = ~clk;  // clk cycle is 20



// wire up the DUT
weights_chaining #(
  .OC0(OC0),
  .COUNTER_WID(2)
) chain_inst (
  .weights_dat(weights_dat),
  .weights_vld(weights_vld),
  .clk(clk),
  .rst_n(rst_n),
  .en_input(en_input),
  .weights_dat_chained(weights_dat_chained),
  .done(done),
  .weights_rdy(weights_rdy)
);




initial begin

  clk <= 0;
  rst_n <= 0;
  
  #20 // sets control signals during neg cycle of clk
  rst_n <= 1;
  en_input <= 1;
  weights_vld <= 0;
  
  #20 // ifmap_vld not ready
  weights_vld <=0;
  
  #20 // data 0 appears at input
  weights_dat <= 1;
  weights_vld <= 1;
  
  #20 //data 1 not ready
  weights_vld <= 0;
  
  #20  // data1 ready
  weights_dat <= 2;
  weights_vld <= 1;
  
  #20 // data2 ready
  weights_dat <= 3;
  weights_vld <= 1;
  
  #20 // data 3 ready
  weights_dat <= 4;
  weights_vld <= 1;
  
  
  #20 // disable
  en_input <= 0;


end


// config vcd display
initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, weights_chaining_tb);
    #20000000;
    $finish(2);
  end



endmodule

