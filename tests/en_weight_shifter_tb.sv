// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-09

module en_weight_shifter_tb;

  localparam IC0 = 4;        // height of the mac array
  localparam OC0 = 4;         // width of the mac array

// local signals
  logic  clk;
  logic  rst_n;
  logic  en;            // en for the entire mac array
  logic  en_weight00;   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
  logic  en_weight [IC0 - 1 : 0][OC0 - 1 : 0];    // en_weight signal for each mac cell


// clk generation
always #10 clk =~clk;


// wire up the dut
en_weight_shifter
# (
  .IC0(IC0),        // height of the mac array
  .OC0(OC0)        // width of the mac array
) dut
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),            // en for the entire mac array
  .en_weight00(en_weight00),   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
  .en_weight(en_weight)     // en_weight signal for each mac cell
);


// send the test signals
  initial begin

    clk   = 0;
    rst_n = 0;
    en    = 0;
    
    #20; 
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;

    #20;  // en_weight for cell 0,0 turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 1; 
    #1;
//    $display("en_weight00 = %d", en_weight00);
//    assert(en_weight00 == 1);
    $display("en_weight[0][0] = %d", en_weight[0][0]);
    assert(en_weight[0][0] == 1);

    #19;  // en_weight for cell (0,1) and cell (1,0) turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    $display("en_weight[0][0] = %d", en_weight[0][0]);
    assert(en_weight[0][0] == 0);
    assert(en_weight[1][0] == 1);
    assert(en_weight[0][1] == 1);

    #19;  // en_weight for cell (0,2) and cell (2,0) turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    assert(en_weight[1][0] == 0);
    assert(en_weight[2][0] == 1);
    assert(en_weight[0][2] == 1);

    #19;  // en_weight for cell (0,3) and cell (3,0) turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    assert(en_weight[2][0] == 0);
    assert(en_weight[3][0] == 1);
    assert(en_weight[0][3] == 1);

    #19;  // en_weight for cell (1,3) and cell (2,2) turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    assert(en_weight[3][0] == 0);
    assert(en_weight[1][3] == 1);
    assert(en_weight[2][2] == 1);


    #19;  // en_weight for cell (2,3) and cell (3,2) turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    assert(en_weight[3][0] == 0);
    assert(en_weight[2][3] == 1);
    assert(en_weight[3][2] == 1);

    
    #19;  // en_weight for cell (3,3) turns high
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    assert(en_weight[3][0] == 0);
    assert(en_weight[3][2] == 0);
    assert(en_weight[3][3] == 1);

   #19;  // en_weight for cells turn low
    rst_n = 1;
    en    = 1;
    en_weight00 = 0;
    #1;
    assert(en_weight[3][0] == 0);
    assert(en_weight[3][2] == 0);
    assert(en_weight[3][3] == 0);
    $display("done");

    end 


initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, en_weight_shifter_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end



endmodule
