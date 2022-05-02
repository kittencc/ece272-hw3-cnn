// Author: Cheryl(Yingqiu) Cao
// Date: 2021-11-08
// Updated: 2022-04-30



module counter_tb;

localparam COUNTER_WID = 8; 

// local signals
logic clk;
logic rst_n;
logic en;
logic [COUNTER_WID-1: 0] count;
logic [COUNTER_WID-1: 0] config_MAX_COUNT;




// clk
always #10 clk = ~clk;  // clk cycle is 20



// wire up the DUT
counter 
#(
  .COUNTER_WID(COUNTER_WID)
)
dut
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .count(count),
  .config_MAX_COUNT(config_MAX_COUNT)
);


initial begin

  clk <= 0;
  rst_n <= 0;
  config_MAX_COUNT = 5;
  
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
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, counter_tb);
  $fsdbDumpMDA(0, counter_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end



endmodule
