// Description: OC0 = 4, load 2 sets of chained data
//              4_3_2_1 and 8_7_6_5
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-17
// updated on: 2022-05-07: switching from DVE to Verdi



module ofmap_PISO_tb;

// loacl parameters
localparam OC0 = 4;
localparam COUNTER_WID = 4;


// local signals
logic clk;
logic rst_n;

  // control signals
logic en_PISO;
logic load;        // load chained data into internal ffs
logic start;       // sel signal for the shifter's input mux, loads chained data into the shifter 
logic chaining_last_one;          // output to the FSM

  // data
logic [32*OC0 - 1 : 0] ofmap_dat_chained;
logic ofmap_rdy;
logic [31 : 0] ofmap_dat;
logic ofmap_vld;

logic [31:0] dat [OC0 - 1 : 0];  // local data to make assignment of chained data easier

// concatenation of dat for chained_data
genvar x;
generate
for (x = 0; x < OC0; x = x + 1) begin
  assign ofmap_dat_chained[(x+1)*32-1 : x*32] = dat[x];
end
endgenerate



// clk
always #10 clk = ~clk;  // clk cycle is 20


// wire up the dut
ofmap_PISO
# (
  .OC0(OC0),
  .COUNTER_WID(COUNTER_WID)
) dut
(
  .clk(clk),
  .rst_n(rst_n),
  .en_PISO(en_PISO),
  .load(load),
  .start(start),
  .chaining_last_one(chaining_last_one),
  .ofmap_dat_chained(ofmap_dat_chained),
  .ofmap_rdy(ofmap_rdy),
  .ofmap_dat(ofmap_dat),
  .ofmap_vld(ofmap_vld)
);


integer i,j;      // counts the # of iteration for the unchaing process

initial begin

  clk   <= 0;
  rst_n <= 0;
  
  #20 // sets control signals during neg cycle of clk
  rst_n     <= 1;
  en_PISO   <= 1;
  
  for ( i = 0; i < 2; i = i + 1 ) begin
    
    #20    // load chained data
    rst_n     <= 1;
    en_PISO   <= 0;
    load      <= 1;
    start     <= 0;
    ofmap_rdy <= 1;

    dat[0] <= i*OC0 + 1;
    dat[1] <= i*OC0 + 2;
    dat[2] <= i*OC0 + 3;
    dat[3] <= i*OC0 + 4;

    #20   // start
    rst_n     <= 1;
    en_PISO   <= 1;
    load      <= 0;
    start     <= 1;
    ofmap_rdy <= 1;

    #20  // pause
    rst_n     <= 1;
    en_PISO   <= 1;
    load      <= 0;
    start     <= 0;
    ofmap_rdy <= 0;     // ofmap bus not ready

    // keep unchaining
    for ( j = 0; j < (OC0-1) ; j = j + 1 ) begin
      #20
      rst_n     <= 1;
      en_PISO   <= 1;
      load      <= 0;
      start     <= 0;
      ofmap_rdy <= 1;   
    end

  end

  // wait
  #20
  rst_n     <= 1;
  en_PISO   <= 1;
  load      <= 0;
  start     <= 0;
  ofmap_rdy <= 0;


end


//initial begin
//    $vcdplusfile("dump.vcd");
//    $vcdplusmemon();
//    $vcdpluson(0, ofmap_PISO_tb);
//    #20000000;
//    $finish(2);
//  end


initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, ofmap_PISO_tb);
  $fsdbDumpMDA(0, ofmap_PISO_tb);
  #10000;
  $finish;
end



endmodule
