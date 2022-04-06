// Description: Testbench for the double buffer
//   For the first 4 cycles, write 1, 2, 3, 4 to ram 1 at addr 1,3, 5, 7
//   switch
//   for the next 5 cycles, write 5, 6, 7, 8, 9 to ram 2 at addr 1,2,3,4,5
//               meanwhile, read ram1 at addr 1,3,5,7
//                          the rdata output should be 1,2,3,4
//   pause for one cycle
//   switch
//   for the next 5 cycles, write 0, 2, 4, 6 to ram 1 at addr 0, 2,4,6
//               meanwhile, read ram2 at addr 1-5
//                          the rdata output should be 5,6,7,8,9
//   switch
//   for the mext 8 cycles, read ram1 at addr 0-7,
//                          the rdata output should be 0, 1,2,2,4,3,6,4
//
//
// Author: Cheryl(Yingqiu) Cao
// Date: 2021-11-28


module double_buffer_tb;

 localparam DATA_WIDTH      = 64;     // original data width 16 * chaining_length of 4
 localparam BANK_ADDR_WIDTH = 8;       // width of read/write addr
 localparam MEM_DEPTH       = 256;     // capacity of the memory

 
 // local signals
  logic clk;
  logic rst_n;
  logic switch_banks;
  logic ren;
  logic [BANK_ADDR_WIDTH - 1 : 0] radr;
  logic  [DATA_WIDTH - 1 : 0] rdata;
  logic wen;
  logic [BANK_ADDR_WIDTH - 1 : 0] wadr;
  logic [DATA_WIDTH - 1 : 0] wdata;


  // clk
  always #10 clk = ~clk;  // clk cycle is 20


  // wire up the DUT
 double_buffer
#( 
  .DATA_WIDTH(DATA_WIDTH),     // original data width 16 * chaining_length of 4
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),       // width of read/write addr
  .MEM_DEPTH(MEM_DEPTH)     // capacity of the memory
) dut 
(
  .clk(clk),
  .rst_n(rst_n),
  .switch_banks(switch_banks),
  .ren(ren),
  .radr(radr),
  .rdata(rdata),
  .wen(wen),
  .wadr(wadr),
  .wdata(wdata)
);

 

initial begin

  clk    <= 0;
  rst_n <= 0;
  switch_banks <= 0;
  
  #20 // sets control signals during neg cycle of clk
  // For the first 4 cycles, write 1, 2, 3, 4 to ram 1 at addr 1,3, 5, 7
  rst_n <= 1;
  wen   <= 1;
  wadr  <= 1;
  wdata <= 1;
  ren   <= 0;

  #20
  wen   <= 1;
  wadr  <= 3;
  wdata <= 2;
  ren   <= 0;

  #20
  wen   <= 1;
  wadr  <= 5;
  wdata <= 3;
  ren   <= 0;


  #20
  wen   <= 1;
  wadr  <= 7;
  wdata <= 4;
  ren   <= 0;

  // switch
  #20
  switch_banks <= 1;
  wen <=0;
  ren <=0;

  //for the next 5 cycles, write 5, 6, 7, 8, 9 to ram 2 at addr 1,2,3,4,5
  //               meanwhile, read ram1 at addr 1,3,5,7
  //                          the rdata output should be 1,2,3,4
  #20
  switch_banks <= 0;
  wen   <= 1;
  wadr  <= 1;
  wdata <= 5;
  ren   <= 1;
  radr  <= 1;

  #20
  wen   <= 1;
  wadr  <= 2;
  wdata <= 6;
  ren   <= 1;
  radr  <= 3;
  $display("rdata = %d", rdata); assert(rdata == 1);

  #20
  wen   <= 1;
  wadr  <= 3;
  wdata <= 7;
  ren   <= 1;
  radr  <= 5;
  $display("rdata = %d", rdata); assert(rdata == 2);

  #20
  wen   <= 1;
  wadr  <= 4;
  wdata <= 8;
  ren   <= 1;
  radr  <= 7;
  $display("rdata = %d", rdata); assert(rdata == 3);

  #20
  wen   <= 1;
  wadr  <= 5;
  wdata <= 9;
  ren   <= 0;
  $display("rdata = %d", rdata); assert(rdata == 4);

  //wait 1 cycle
  #20
  wen <= 0;
  ren <= 0;

  // switch
  #20
  switch_banks <= 1;
  wen <=0;
  ren <=0;

//for the next 5 cycles, write 0, 2, 4, 6 to ram 1 at addr 0, 2,4,6
//               meanwhile, read ram2 at addr 1-5
//                          the rdata output should be 5,6,7,8,9
  #20
  switch_banks <= 0;
  wen   <= 1;
  wadr  <= 0;
  wdata <= 0;
  ren   <= 1;
  radr  <= 1;

  #20
  wen   <= 1;
  wadr  <= 2;
  wdata <= 2;
  ren   <= 1;
  radr  <= 2;
  $display("rdata = %d", rdata); assert(rdata == 5);

  #20
  wen   <= 1;
  wadr  <= 4;
  wdata <= 4;
  ren   <= 1;
  radr  <= 3;
  $display("rdata = %d", rdata); assert(rdata == 6);

  #20
  wen   <= 1;
  wadr  <= 6;
  wdata <= 6;
  ren   <= 1;
  radr  <= 4;
  $display("rdata = %d", rdata); assert(rdata == 7);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 5;
  $display("rdata = %d", rdata); assert(rdata == 8);

// switch
  #20
  switch_banks <= 1;
  wen   <= 0;
  ren   <= 0;
  $display("rdata = %d", rdata); assert(rdata == 9);


//   for the mext 8 cycles, read ram1 at addr 0-7,
//                          the rdata output should be 0, 1,2,2,4,3,6,4
  #20
  switch_banks <= 0;
  wen   <= 0;
  ren   <= 1;
  radr  <= 0;

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 1;
  $display("rdata = %d", rdata); assert(rdata == 0);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 2;
  $display("rdata = %d", rdata); assert(rdata == 1);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 3;
  $display("rdata = %d", rdata); assert(rdata == 2);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 4;
  $display("rdata = %d", rdata); assert(rdata == 2);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 5;
  $display("rdata = %d", rdata); assert(rdata == 4);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 6;
  $display("rdata = %d", rdata); assert(rdata == 3);

  #20
  wen   <= 0;
  ren   <= 1;
  radr  <= 7;
  $display("rdata = %d", rdata); assert(rdata == 6);

  #20
  wen   <= 0;
  ren   <= 01;
  $display("rdata = %d", rdata); assert(rdata == 4);

end


  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, double_buffer_tb);
    #20000000;
    $finish(2);
  end







endmodule
