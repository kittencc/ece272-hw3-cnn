// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-13
// Updated on 2022-04-30; dve => verdi related changes

module input_chaining_tb;

localparam IC0 = 4;

// local signals
logic [15:0] input_dat;
logic        input_vld;
logic        clk;
logic        rst_n;
logic        en_input;

logic [16*IC0-1:0] input_dat_chained;
logic              done;
logic              input_rd;


// clk
always #10 clk = ~clk;  // clk cycle is 20



// wire up the DUT
input_chaining
#(
  .IC0(IC0),
  .COUNTER_WID(2)
) 
chain_inst 
(
  .input_dat(input_dat),
  .input_vld(input_vld),
  .clk(clk),
  .rst_n(rst_n),
  .en_input(en_input),
  .input_dat_chained(input_dat_chained),
  .chaining_last_one(chaining_last_one),
  .done(done),
  .input_rdy(input_rdy)
);




initial begin

  clk <= 0;
  rst_n <= 0;
  
  #20 // sets control signals during neg cycle of clk
  rst_n <= 1;
  en_input <= 1;
  input_vld <= 0;
  
  #20 // ifmap_vld not ready
  input_vld <=0;
  
  #20 // data 0 appears at input
  input_dat <= 1;
  input_vld <= 1;
  
  #20 //data 1 not ready
  input_vld <= 0;
  
  #20  // data1 ready
  input_dat <= 2;
  input_vld <= 1;
  
  #20 // data2 ready
  input_dat <= 3;
  input_vld <= 1;
  
  #20 // data 3 ready
  input_dat <= 4;
  input_vld <= 1;
  
  
  #20 // disable
  en_input <= 0;


end


// config vcd display
// initial begin
//    $vcdplusfile("dump.vcd");
//    $vcdplusmemon();
//    $vcdpluson(0, input_chaining_tb);
//    #20000000;
//    $finish(2);
//  end


initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, input_chaining_tb);
  $fsdbDumpMDA(0, input_chaining_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end



endmodule

