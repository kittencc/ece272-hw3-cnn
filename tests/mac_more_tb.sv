// Description: IC0 = OC0 = 2
//              FX = FY = 1
//              OY0 = OX0 = 2
//              Following data from LSB to MSB:
//              weight_in: 1_2, 3_4
//              accum_in:  -1_1, -2_2, -3_3, -4_4
//              ifmap_in: 5_9, 6_10, 7_11, 8_12
//      expected accum_out: 31_47, 34_54, 37_61, 40_68
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-10
// Updated on: 2022-04-23

module mac_more_tb;

// parameters
localparam IC0 = 2;
localparam OC0 = 2;

// local signals
  logic  clk;
  logic  rst_n;
  logic  en;            // en for the entire mac array
  logic  en_weight00;   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
  logic ifmap_fifo_enq;
  logic [16*IC0 - 1 : 0] ifmap_dat_chained_fifo_in;
  logic weight_fifo_enq;
  logic [16*OC0 - 1 : 0] weight_dat_chained_fifo_in;
  logic accum_in_fifo_enq;
  logic [32*OC0 - 1 : 0] accum_in_chained_fifo_in;
  logic accum_out_fifo_enq;
  logic [32*OC0 - 1 : 0] accum_out_chained_fifo_out;


// clk
always #10 clk = ~clk;  // clk cycle is 20



// wire up the dut
mac_more
# (
  .IC0(IC0),        // height of the mac array
  .OC0(OC0)         // width of the mac array
)
dut
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .en_weight00(en_weight00),
  .ifmap_fifo_enq(ifmap_fifo_enq),
  .ifmap_dat_chained_fifo_in(ifmap_dat_chained_fifo_in),
  .weight_fifo_enq(weight_fifo_enq),
  .weight_dat_chained_fifo_in(weight_dat_chained_fifo_in),
  .accum_in_fifo_enq(accum_in_fifo_enq),
  .accum_in_chained_fifo_in(accum_in_chained_fifo_in),
  .accum_out_fifo_enq(accum_out_fifo_enq),
  .accum_out_chained_fifo_out(accum_out_chained_fifo_out)
);



// send the test signals
initial begin

  clk   = 1'b0;
  rst_n = 1'b0;
  en    = 1'b0;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b0;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b0;
  accum_out_fifo_enq = 1'b0;
  
  #20 // enqueue 1st weight data
  // weight data goes 1 cycle earlier than ifmap and accum_in
  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b1;
  ifmap_fifo_enq     = 1'b0;
  weight_fifo_enq    = 1'b1;
  accum_in_fifo_enq  = 1'b0;
  accum_out_fifo_enq = 1'b0;

  //concatenation for OC0 = 2
  // MSB -> LSB
  weight_dat_chained_fifo_in = {signed'(16'(2)) , signed'(16'(1))};

  #20 // enqueue 1st ifmap/accum_in data 
  // weight data goes 1 cycle earlier than ifmap and accum_in
  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b1;
  weight_fifo_enq    = 1'b1;
  accum_in_fifo_enq  = 1'b1;
  accum_out_fifo_enq = 1'b0;

  //concatenation for OC0 = 2
  // MSB -> LSB
  weight_dat_chained_fifo_in = {signed'(16'(4)) , signed'(16'(3))};
  ifmap_dat_chained_fifo_in  = {signed'(16'(9)) , signed'(16'(5))};
  accum_in_chained_fifo_in   = {signed'(32'(1)) , signed'(32'(-1))};
//  $display("accum_in_chained_fifo_in = %h", accum_in_chained_fifo_in);


  #20 // enqueue 2nd ifmap/accum_in data 
  // weight data goes 1 cycle earlier than ifmap and accum_in
  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b1;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b1;
  accum_out_fifo_enq = 1'b0;

  //concatenation for OC0 = 2
  weight_dat_chained_fifo_in = {signed'(16'(4)) , signed'(16'(3))};
  ifmap_dat_chained_fifo_in  = {signed'(16'(10)) , signed'(16'(6))};
  accum_in_chained_fifo_in   = {signed'(32'(2)) , signed'(32'(-2))};
//  $display("accum_in_chained_fifo_in = %h", accum_in_chained_fifo_in);


  #20 // enqueue 3rd ifmap/accum_in data 
  // weight data goes 1 cycle earlier than ifmap and accum_in
  // 1st accum_out data appears at the input of the accum_out_skew_fifo
  // enqueue 1st accum_out data
  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b1;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b1;
  accum_out_fifo_enq = 1'b1;

  //concatenation for OC0 = 2
  weight_dat_chained_fifo_in = {signed'(16'(4)) , signed'(16'(3))};
  ifmap_dat_chained_fifo_in  = {signed'(16'(11)) , signed'(16'(7))};
  accum_in_chained_fifo_in   = {signed'(32'(3)) , signed'(32'(-3))};
//  $display("accum_in_chained_fifo_in = %h", accum_in_chained_fifo_in);


  #19 // enqueue 4th ifmap/accum_in data 
  // weight data goes 1 cycle earlier than ifmap and accum_in
  // 2nd accum_out data appears at the input of the accum_out_skew_fifo
  // enqueue 2nd accum_out data

  // 1st accum_out data appears at the output skewed_fifo
  // Expect {47_31}
  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b1;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b1;
  accum_out_fifo_enq = 1'b1;

  //concatenation for OC0 = 2
  weight_dat_chained_fifo_in = {signed'(16'(4)) , signed'(16'(3))};
  ifmap_dat_chained_fifo_in  = {signed'(16'(12)) , signed'(16'(8))};
  accum_in_chained_fifo_in   = {signed'(32'(4)) , signed'(32'(-4))};
//  $display("accum_in_chained_fifo_in = %h", accum_in_chained_fifo_in);

  #1
  $display("accum_out_chained_fifo_out[0] = %d",
  accum_out_chained_fifo_out[31:0]);
  assert(accum_out_chained_fifo_out[31:0] == 31);

  $display("accum_out_chained_fifo_out[1] = %d",
  accum_out_chained_fifo_out[63:32]);
  assert(accum_out_chained_fifo_out[63:32] == 47);



  #19
  // enqueue 3rd accum_out data
  // 2nd accum_out data appears at the output skewed_fifo
  // Expect {54_34}

  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b0;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b0;
  accum_out_fifo_enq = 1'b1;
  #1
  $display("accum_out_chained_fifo_out[0] = %d",
  accum_out_chained_fifo_out[31:0]);
  assert(accum_out_chained_fifo_out[31:0] == 34);

  $display("accum_out_chained_fifo_out[1] = %d",
  accum_out_chained_fifo_out[63:32]);
  assert(accum_out_chained_fifo_out[63:32] == 54);


  #19
  // enqueue 4th accum_out data
  // 3rd accum_out data appears at the output skewed_fifo
  // Expect {61_37}

  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b0;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b0;
  accum_out_fifo_enq = 1'b1;
  #1
  $display("accum_out_chained_fifo_out[0] = %d",
  accum_out_chained_fifo_out[31:0]);
  assert(accum_out_chained_fifo_out[31:0] == 37);

  $display("accum_out_chained_fifo_out[1] = %d",
  accum_out_chained_fifo_out[63:32]);
  assert(accum_out_chained_fifo_out[63:32] == 61);



  #19
  // 4th accum_out data appears at the output skewed_fifo
  // Expect {68_40}
  rst_n = 1'b1;
  en    = 1'b1;
  en_weight00 = 1'b0;
  ifmap_fifo_enq     = 1'b0;
  weight_fifo_enq    = 1'b0;
  accum_in_fifo_enq  = 1'b0;
  accum_out_fifo_enq = 1'b0;
  #1
  $display("accum_out_chained_fifo_out[0] = %d",
  accum_out_chained_fifo_out[31:0]);
  assert(accum_out_chained_fifo_out[31:0] == 40);

  $display("accum_out_chained_fifo_out[1] = %d",
  accum_out_chained_fifo_out[63:32]);
  assert(accum_out_chained_fifo_out[63:32] == 68);


  #20
  rst_n = 1'b1;
  en    = 1'b0;
  en_weight00 = 1'b0;
 
$display("done");

end


initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, mac_more_tb);
  $fsdbDumpMDA(0, mac_more_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end



endmodule
