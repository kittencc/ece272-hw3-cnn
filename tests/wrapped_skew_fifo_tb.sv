// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-09

module wrapped_skew_fifo_tb;

// local parameters
  localparam IFMAP_WIDTH = 16;
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
wrapped_skew_fifo
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
    clk   <= 0;
    rst_n <= 1;
    en    <= 0;
    
    #20 
    rst_n <= 0;
    en    <= 0;
  
    #20 
    rst_n <= 1;
    en    <= 1;
    enq   <= 1;
    d_in_r[0] <= 1;
    d_in_r[1] <= 2;
    d_in_r[2] <= 3;
    d_in_r[3] <= 4;

    #20 
    rst_n <= 1;
    en    <= 1;
    enq   <= 1;
    d_in_r[0] <= 2;
    d_in_r[1] <= 3;
    d_in_r[2] <= 4;
    d_in_r[3] <= 5;
    assert(d_out_w[1] == 2);

    #20
    rst_n <= 1;
    en    <= 1;
    enq   <= 1;
    d_in_r[0] <= 3;
    d_in_r[1] <= 4;
    d_in_r[2] <= 5;
    d_in_r[3] <= 6;
    assert(d_out_w[1] == 3);
    assert(d_out_w[2] == 3);

    #20
    rst_n <= 1;
    en    <= 0;       // what about turn en = 0 next cycle
    enq   <= 0;  
    d_in_r[0] <= 4;
    d_in_r[1] <= 5;
    d_in_r[2] <= 6;
    d_in_r[3] <= 7;
    assert(d_out_w[1] == 4);
    assert(d_out_w[2] == 4);
    assert(d_out_w[3] == 4);

    $display("done");
  end

initial begin
  $fsdbDumpfile("dump.fsdb");
  // dumps signal waveforms
  $fsdbDumpvars(0, wrapped_skew_fifo_tb);
  // dumps waveforms for multi-dimentional array signals
  $fsdbDumpMDA(0, wrapped_skew_fifo_tb);
//  $fsdbDumpon;
  #10000;
//  $fsdbDumpoff;
  $finish;
end



endmodule
