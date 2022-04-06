// Description: - write 1-4 into the double buffer, with one cycle delay,
//                read them out from the same bank. rdata_accum output
//                should be 1-4.
//              - switch
//              - read ofmap data out from addr 1-4, rdata_ofmap output
//              should be 1-4.
//              - write 5-8 into the double buffer @ addr 1-4. With one
//              cycle delay, read them out from the same bank.
//              radata_accum output should be 5-6.i
//              - switch
//              - read ofmmap_data out frpm addr 1-4, rdata_ofmap output
//              should be 5-8.
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-09


module accum_double_buffer_tb;

 localparam DATA_WIDTH      = 64;     // original data width 16 * chaining_length of 4
 localparam BANK_ADDR_WIDTH = 8;       // width of read/write addr
 localparam MEM_DEPTH       = 256;     // capacity of the memory


// lacal signals begin
  logic clk;
  logic rst_n;
  logic switch_banks;
// 1 read 1 write ports for the mac array and the accum sum 
  logic wen;
  logic [BANK_ADDR_WIDTH - 1 : 0] waddr;
  logic [DATA_WIDTH - 1 : 0] wdata;
  logic ren;
  logic [BANK_ADDR_WIDTH - 1 : 0] raddr_accum;
  logic [DATA_WIDTH - 1 : 0] rdata_accum;

 // 1 read port to send ofmap data out
  logic ren_ofmap;
  logic [BANK_ADDR_WIDTH - 1 : 0] raddr_ofmap;
  logic [DATA_WIDTH - 1 : 0] rdata_ofmap;
  // local signals end


  // clk
  always #10 clk = ~clk;  // clk cycle is 20



// connect the DUT
 accum_double_buffer
#( 
  .DATA_WIDTH(DATA_WIDTH),     // original data width 16 * chaining_length of 4
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),       // width of read/write addr
  .MEM_DEPTH(MEM_DEPTH)     // capacity of the memory
) dut 
(
  .clk(clk),
  .rst_n(rst_n),
  .switch_banks(switch_banks),
  .wen(wen),
  .waddr(waddr),
  .wdata(wdata),
  .ren(ren),
  .raddr_accum(raddr_accum),
  .rdata_accum(rdata_accum),
  .ren_ofmap(ren_ofmap),
  .raddr_ofmap(raddr_ofmap),
  .rdata_ofmap(rdata_ofmap)
);




// feed the input control signals
initial begin

  clk    <= 0;
  rst_n <= 0;
  switch_banks <= 0;
  
  #20 // sets control signals during neg cycle of clk
  // For the first 4 cycles, write 1, 2, 3, 4 to ram 1 at addr 1,3, 5, 7
  rst_n <= 1;
  wen   <= 1;
  waddr  <= 1;
  wdata <= 1;
  ren   <= 0;
  ren_ofmap <= 0;

  #20 // starting from this cycle, read rdata_accum from addr 1-4
  rst_n <= 1;
  wen   <= 1;
  waddr  <= 2;
  wdata <= 2;
  ren         <= 1;
  raddr_accum <= 1;
  ren_ofmap   <= 0;
  raddr_ofmap <= 0;

  #20
  rst_n <= 1;
  wen   <= 1;
  waddr  <= 3;
  wdata <= 3;
  assert( rdata_accum == 1 );
  ren         <= 1;
  raddr_accum <= 2;
  ren_ofmap   <= 0;
  raddr_ofmap <= 0;

  #20   // writing the last accum data
  rst_n <= 1;
  wen   <= 1;
  waddr  <= 4;
  wdata <= 4;
  assert( rdata_accum == 2 );
  ren         <= 1;
  raddr_accum <= 3;
  ren_ofmap   <= 0;
  raddr_ofmap <= 0;

 #20   // reading the last accum data
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 assert( rdata_accum == 3 );
 ren         <= 1;
 raddr_accum <= 4;
 ren_ofmap   <= 0;
 raddr_ofmap <= 0;

 #20   // switch, and finishing reading accum data
 switch_banks <= 1;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 assert( rdata_accum == 4 );
 ren         <= 0;
 raddr_accum <= 0;
 ren_ofmap   <= 0;
 raddr_ofmap <= 0;

 #20 // new bank after switch
 // writing accum_data 5-8 to addr 1-4
 // at the same time read ofmap_data from the other bank
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 1;
 waddr  <= 1;
 wdata <= 5;
 ren         <= 0;
 raddr_accum <= 0;
 ren_ofmap   <= 1;
 raddr_ofmap <= 1;

 #20 //starting from this cycle, read accum_data from addr 1-4
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 1;
 waddr  <= 2;
 wdata <= 6;
 ren         <= 1;
 raddr_accum <= 1;
 assert( rdata_ofmap == 1 );
 ren_ofmap   <= 1;
 raddr_ofmap <= 2;

 #20
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 1;
 waddr  <= 3;
 wdata <= 7;
 assert( rdata_accum == 5 );
 ren         <= 1;
 raddr_accum <= 2;
 assert( rdata_ofmap == 2 );
 ren_ofmap   <= 1;
 raddr_ofmap <= 3;

 #20 // writing last accum_data, reading last ofmap_data
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 1;
 waddr  <= 4;
 wdata <= 8;
 assert( rdata_accum == 6 );
 ren         <= 1;
 raddr_accum <= 3;
 assert( rdata_ofmap == 3 );
 ren_ofmap   <= 1;
 raddr_ofmap <= 4;

 #20  // reading last accum_data
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 assert( rdata_accum == 7 );
 ren         <= 1;
 raddr_accum <= 4;
 assert( rdata_ofmap == 4 );
 ren_ofmap   <= 0;
 raddr_ofmap <= 0;

 #20  // switch
 switch_banks <= 1;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 assert( rdata_accum == 8 );
 ren         <= 0;
 raddr_accum <= 0;
 ren_ofmap   <= 0;
 raddr_ofmap <= 0;

 #20  // read the 2nd bank of ofmap data
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 ren         <= 0;
 raddr_accum <= 0;
 ren_ofmap   <= 1;
 raddr_ofmap <= 1;

 #20
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 ren         <= 0;
 raddr_accum <= 0;
 assert( rdata_ofmap == 5 );
 ren_ofmap   <= 1;
 raddr_ofmap <= 2;

 #20
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 ren         <= 0;
 raddr_accum <= 0;
 assert( rdata_ofmap == 6 );
 ren_ofmap   <= 1;
 raddr_ofmap <= 3;

 #20
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 ren         <= 0;
 raddr_accum <= 0;
 assert( rdata_ofmap == 7 );
 ren_ofmap   <= 1;
 raddr_ofmap <= 4;


 // last assert cycle
 #20
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 ren         <= 0;
 raddr_accum <= 0;
 assert( rdata_ofmap == 8 );
 ren_ofmap   <= 0;
 raddr_ofmap <= 0;

 // stop
 #20
 switch_banks <= 0;
 rst_n <= 1;
 wen   <= 0;
 waddr  <= 0;
 wdata <= 0;
 ren         <= 0;
 raddr_accum <= 0;
 ren_ofmap   <= 0;
 raddr_ofmap <= 0;



end


initial begin
  $vcdplusfile("dump.vcd");
  $vcdplusmemon();
  $vcdpluson(0, accum_double_buffer_tb);
  #20000000;
  $finish(2);
end


endmodule
