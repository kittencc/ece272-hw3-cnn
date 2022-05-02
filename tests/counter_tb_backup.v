// Author: Cheryl(Yingqiu) Cao
// Date: 2021-11-08



module counter_tb;

localparam MAX_COUNT = 5;
localparam COUNTER_WID = 3; 

// local signals
logic clk;
logic rst_n;
logic en;
logic [COUNTER_WID-1: 0] count;




// clk
always #10 clk = ~clk;  // clk cycle is 20



// wire up the DUT
counter 
#(
  .MAX_COUNT(MAX_COUNT)
//  .COUNTER_WID(`COUNTER_WID)
)
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .count(count)
);


initial begin

  clk <= 0;
  rst_n <= 0;
  
  #20 // sets control signals during neg cycle of clk
  rst_n <= 1;
  en <= 1;

  #20
  en <= 0;

  #40
  en <= 1;

  #100
  rst_n <= 0;

end
 

initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, counter_tb);
    #20000000;
    $finish(2);
  end



endmodule
