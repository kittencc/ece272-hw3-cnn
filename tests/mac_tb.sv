// Description: 
//              ifmap_in   weight_in  accum_in   en_weight  |  accum_out
//                x         1           x            1      |     x
//                1         1           1            0      |     x
//                2         2           2            1      |     2
//                3         3           3            0      |     4
//                4         4           4            1      |     9
//                5         5           5            0      |     12
//                                                          |     25
//    weight_in needs to be ready 1 cycle earlier than ifmap_in and
//    accum_in
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-2


module mac_tb;

// local signal ++
  logic  clk;
  logic  rst_n;
  logic  en;            // en for the entire mac module
  logic  en_weight;     // en signal for the weight FF
  logic  [15 : 0]  ifmap_in;
  logic  [15 : 0] weight_in;
  logic  [31 : 0]  accum_in;
  logic  [15 : 0] ifmap_out;
  logic  [31 : 0] accum_out;

// local signal --


// clk
always #10 clk = ~clk;  // clk cycle is 20



// wire up the dut
mac mac_inst (
  .clk(clk),
  .rst_n(rst_n),
  .en(en),            // en for the entire mac module
  .en_weight(en_weight),     // en signal for the weight FF
  .ifmap_in(ifmap_in),
  .weight_in(weight_in),
  .accum_in(accum_in),
  .ifmap_out(ifmap_out),
  .accum_out(accum_out)
);


// send the test signals
initial begin

  clk   <= 0;
  rst_n <=0;

  // start, cycle 0
  #20
  rst_n     <= 1;
  en        <= 1;
  en_weight <= 1;
  ifmap_in  <= 0;
  weight_in <= 1;
  accum_in  <= 0;

 // cycle 1
  #20
  rst_n     <= 1;
  en        <= 1;
  en_weight <= 0;
  ifmap_in  <= 1;
  weight_in <= 1;
  accum_in  <= 1;

 // cycle 2
  #20
  rst_n     <= 1;
  en        <= 1;
  en_weight <= 1;
  ifmap_in  <= 2;
  weight_in <= 2;
  accum_in  <= 2;
  $display("accum_out = %d", accum_out); assert(accum_out == 2);

 // cycle 3
  #20
  rst_n     <= 1;
  en        <= 1;
  en_weight <= 0;
  ifmap_in  <= 3;
  weight_in <= 3;
  accum_in  <= 3;
  $display("accum_out = %d", accum_out); assert(accum_out == 4);

 // cycle 4
  #20
  rst_n     <= 1;
  en        <= 1;
  en_weight <= 1;
  ifmap_in  <= 4;
  weight_in <= 4;
  accum_in  <= 4;
  $display("accum_out = %d", accum_out); assert(accum_out == 9);

 // cycle 5
  #20
  rst_n     <= 1;
  en        <= 1;
  en_weight <= 0;
  ifmap_in  <= 5;
  weight_in <= 5;
  accum_in  <= 5;
  $display("accum_out = %d", accum_out); assert(accum_out == 12);

  #20
  $display("accum_out = %d", accum_out); assert(accum_out == 25);




end


// dumping fsdb waveform for Verdi
initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0);
  $fsdbDumpon;
  #1000;
  $fsdbDumpoff;
  $finish(2);
end


endmodule
