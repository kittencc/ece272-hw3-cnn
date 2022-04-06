// Description:
//  IC0 = OC0 = 4
//  en_weight goes high for each row one by one (2 cycles) and then turn
//  off
//  chaining goes MSB -> LSB
//  en_weight weight_chained  ifmap_chained  accum_in |  accum_out 
//      1           1_1           0_0             0_0   |    
//      1           2_2           2_2             0_2   |
//      0           3_3           3_3             3_3   |
//      0           4_4           4_4             4_4   |   4_10
//      0           0             0               0     |   11_14
//     cycle 6                                          |   15_8
//     cycle 7                                          |   4_0
//     cycle 8                                          |   0_4
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-03


module mac_array_tb;


  localparam IC0 = 2;
  localparam OC0 = 2;

// local signals ++
  logic  clk;
  logic  rst_n;
  logic  en;            // en for the entire mac array
  logic  en_weight [IC0 - 1 : 0][OC0 - 1 : 0];     // en_weight signal for each mac cell

  logic [16*OC0 - 1 : 0] weight_dat_chained;
  logic [16*IC0 - 1 : 0] ifmap_dat_chained;
  logic [32*OC0 - 1 : 0] accum_in_chained;
  logic [32*OC0 - 1 : 0] accum_out_chained;
 
// local signals --



// clk
always #10 clk = ~clk;  // clk cycle is 20



// connect the mac array
  mac_array
  # (
    .IC0(IC0),        // height of the mac array
    .OC0(OC0)        // width of the mac array
  )  
  dut
  (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),            // en for the entire mac array
    .en_weight(en_weight),     // en_weight signal for each mac cell
    .weight_dat_chained(weight_dat_chained),
    .ifmap_dat_chained(ifmap_dat_chained),
    .accum_in_chained(accum_in_chained),
    .accum_out_chained(accum_out_chained)
);


initial begin

  clk <= 0;
  rst_n <= 0;

  //cycle 1
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{1,1};    // enable row IC0 = 0
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(1), 16'(1)};
  ifmap_dat_chained <= 0;
  accum_in_chained <= 0;
 
 //cycle 2
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // enable row IC0 = 1
  en_weight[1] <= '{1,1};
  weight_dat_chained <= {16'(2), 16'(2)};
  ifmap_dat_chained <= {16'(2), 16'(2)};
  accum_in_chained <= {32'(0), 32'(2)};

 //cycle 3
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // disable weight input
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(3), 16'(3)};
  ifmap_dat_chained <= {16'(3), 16'(3)};
  accum_in_chained <= {32'(3), 32'(3)};

 //cycle 4
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // disable weight input
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(4), 16'(4)};
  ifmap_dat_chained <= {16'(4), 16'(4)};
  accum_in_chained <= {32'(4), 32'(4)};
  $display("accum[0] = %d", accum_out_chained[31:0]); 
  assert( accum_out_chained[31:0] == 10);
  $display("accum[1] = %d", accum_out_chained[63:32]);
  assert(accum_out_chained[63:32] == 4);

 //cycle 5
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // disable weight input
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(0), 16'(0)};
  ifmap_dat_chained <= {16'(0), 16'(0)};
  accum_in_chained <= {32'(0), 32'(0)};
  $display("accum[0] = %d", accum_out_chained[31:0]); 
  assert( accum_out_chained[31:0] == 14);
  $display("accum[1] = %d", accum_out_chained[63:32]);
  assert(accum_out_chained[63:32] == 11);


 //cycle 6
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // disable weight input
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(0), 16'(0)};
  ifmap_dat_chained <= {16'(0), 16'(0)};
  accum_in_chained <= {32'(0), 32'(0)};
  $display("accum[0] = %d", accum_out_chained[31:0]); 
  assert( accum_out_chained[31:0] == 8);
  $display("accum[1] = %d", accum_out_chained[63:32]);
  assert(accum_out_chained[63:32] == 15);


 //cycle 7
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // disable weight input
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(0), 16'(0)};
  ifmap_dat_chained <= {16'(0), 16'(0)};
  accum_in_chained <= {32'(0), 32'(0)};
  $display("accum[0] = %d", accum_out_chained[31:0]); 
  assert( accum_out_chained[31:0] == 0);
  $display("accum[1] = %d", accum_out_chained[63:32]);
  assert(accum_out_chained[63:32] == 4);


 //cycle 8
  #20
  rst_n <= 1;
  en <= 1;
  en_weight[0] <= '{0,0};    // disable weight input
  en_weight[1] <= '{0,0};
  weight_dat_chained <= {16'(0), 16'(0)};
  ifmap_dat_chained <= {16'(0), 16'(0)};
  accum_in_chained <= {32'(0), 32'(0)};
  $display("accum[0] = %d", accum_out_chained[31:0]); 
  assert( accum_out_chained[31:0] == 0);
  $display("accum[1] = %d", accum_out_chained[63:32]);
  assert(accum_out_chained[63:32] == 0);



end
 
 
// dumping fsdb waveform for Verdi
//initial begin
//  $fsdbDumpfile("dump.fsdb");
//  $fsdbDumpvars(0);
//  $fsdbDumpon;
//  #10000;
//  $fsdbDumpoff;
//  $finish(2);
//end

initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, mac_array_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end


endmodule
