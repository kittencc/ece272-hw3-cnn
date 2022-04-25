// Description: enq 4 data for fifo[3]
//             - fifo[3]: enq 1,2,3,4
//             - fifo[2]: enq 1,2,3
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-23

module accum_out_skew_fifo_tb;

// local parameters
  localparam IFMAP_WIDTH = 32;
  localparam ARRAY_HEIGHT = 4;

// local signals
  logic clk;
  logic rst_n;
  logic en;
  logic enq;
  logic signed [IFMAP_WIDTH - 1 : 0] d_in_r [ARRAY_HEIGHT - 1 : 0];
  logic signed [IFMAP_WIDTH - 1 : 0] d_out_w [ARRAY_HEIGHT - 1 : 0];


// clk generation
always #10 clk =~clk;

// connect the dut
accum_out_skew_fifo
# (
  .IFMAP_WIDTH(IFMAP_WIDTH),
  .ARRAY_HEIGHT(ARRAY_HEIGHT)
) dut
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .enq(enq),
  .d_in_r(d_in_r),
  .d_out_w(d_out_w)
);


// send the test signals
  initial begin
    clk   = 0;
    rst_n = 1;
    en    = 0;
    
    #20 
    rst_n = 0;
    en    = 0;
  
    #20 
    rst_n = 1;
    en    = 1;
    enq   = 1;
    d_in_r[3] = 1;
    d_in_r[2] = 0;
    d_in_r[1] = 0;
    d_in_r[0] = 0;

    #20 
    rst_n = 1;
    en    = 1;
    enq   = 1;
    d_in_r[3] = 2;
    d_in_r[2] = 1;
    d_in_r[1] = 0;
    d_in_r[0] = 0;

    #20 
    rst_n = 1;
    en    = 1;
    enq   = 1;
    d_in_r[3] = 3;
    d_in_r[2] = 2;
    d_in_r[1] = 1;
    d_in_r[0] = 0;

    #20 
    rst_n = 1;
    en    = 1;
    enq   = 1;
    d_in_r[3] = 4;
    d_in_r[2] = 3;
    d_in_r[1] = 2;
    d_in_r[0] = 1;

    #19 
    rst_n = 1;
    en    = 1;
    enq   = 0;
    d_in_r[3] = 5;
    d_in_r[2] = 4;
    d_in_r[1] = 3;
    d_in_r[0] = 2;
    #1
    $display("d_out_w[0] = %d ", d_out_w[0]); assert(d_out_w[0] == 2);
    $display("d_out_w[1] = %d ", d_out_w[1]); assert(d_out_w[1] == 2);
    $display("d_out_w[2] = %d ", d_out_w[2]); assert(d_out_w[2] == 2);
    $display("d_out_w[3] = %d ", d_out_w[3]); assert(d_out_w[3] == 2);

    #19
    rst_n = 1;
    en    = 1;
    enq   = 0;
    d_in_r[3] = 6;
    d_in_r[2] = 5;
    d_in_r[1] = 4;
    d_in_r[0] = 3;
    #1
    $display("d_out_w[0] = %d ", d_out_w[0]); assert(d_out_w[0] == 3);
    $display("d_out_w[1] = %d ", d_out_w[1]); assert(d_out_w[1] == 3);
    $display("d_out_w[2] = %d ", d_out_w[2]); assert(d_out_w[2] == 3);
    $display("d_out_w[3] = %d ", d_out_w[3]); assert(d_out_w[3] == 3);

    #19
    rst_n = 1;
    en    = 1;
    enq   = 0;
    d_in_r[3] = 7;
    d_in_r[2] = 6;
    d_in_r[1] = 5;
    d_in_r[0] = 4;
    #1
    $display("d_out_w[0] = %d ", d_out_w[0]); assert(d_out_w[0] == 4);
    $display("d_out_w[1] = %d ", d_out_w[1]); assert(d_out_w[1] == 4);
    $display("d_out_w[2] = %d ", d_out_w[2]); assert(d_out_w[2] == 4);
    $display("d_out_w[3] = %d ", d_out_w[3]); assert(d_out_w[3] == 4);

    #19
    rst_n = 1;
    en    = 1;
    enq   = 0;
    d_in_r[3] = 8;
    d_in_r[2] = 7;
    d_in_r[1] = 6;
    d_in_r[0] = 5;
   #1

   $display("done");
  end




initial begin
  $fsdbDumpfile("dump.fsdb");
  // dumps signal waveforms
  $fsdbDumpvars(0, accum_out_skew_fifo_tb);
  // dumps waveforms for multi-dimentional array signals
  $fsdbDumpMDA(0, accum_out_skew_fifo_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end


endmodule
