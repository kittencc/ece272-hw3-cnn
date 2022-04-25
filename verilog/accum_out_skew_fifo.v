// Description: skewed fifo at the input pf the accum_out double buffer
//              and the output of the mac_array
//              We needed a new skewed fifo, because accum_out data from
//              the mac_array does not arrive at the same time for each
//              fifo/col.
//              - one enq signal for the entire module: for the 1st col
//                the enq signa for other fifo/cols gets derived from the
//                1st one.
//              - d_out from each fifo appears at the same time
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-23


module accum_out_skew_fifo
# (
  parameter IFMAP_WIDTH = 16,
  parameter ARRAY_HEIGHT = 4     // equals to OC0
)
(
  input logic clk,
  input logic rst_n,
  input logic en,
  input logic enq,
  input logic signed [IFMAP_WIDTH - 1 : 0] d_in_r [ARRAY_HEIGHT - 1 : 0],
  output logic signed [IFMAP_WIDTH - 1 : 0] d_out_w [ARRAY_HEIGHT - 1 : 0]

);


// local signals ++
  logic full_n_w [ARRAY_HEIGHT - 1 : 0];
  logic empty_n_w [ARRAY_HEIGHT - 1 : 0];
  logic enq_r [ARRAY_HEIGHT - 1 : 0];
  logic deq_r [ARRAY_HEIGHT - 1 : 0];
  // saves d_out temporarily for the mux
  logic signed [IFMAP_WIDTH - 1 : 0] d_out_tmp [ARRAY_HEIGHT - 1 : 0];

// local signals --



// connect input_skew_fifo module
  input_skew_fifos
  #(
    .IFMAP_WIDTH(IFMAP_WIDTH),
    .ARRAY_HEIGHT(ARRAY_HEIGHT)
  ) input_skew_fifos_inst (
    .clk(clk),
    .rst_n(rst_n),
    .full_n(full_n_w),
    .enq(enq_r),
    .d_in(d_in_r),
    .empty_n(empty_n_w),
    .deq(deq_r),
    .d_out(d_out_tmp)
  );



// shifter for the enq_r signal
genvar i;

// connect 3 ffs into a shifter
generate
  for (i = 1; i < ARRAY_HEIGHT; i = i + 1) begin
       // connect the FFs
      ff #(.DATA_WIDTH(1)) ff_inst
      (
        .rst_n(rst_n),
        .en(en),
        .clk(clk),
        .D(enq_r[ARRAY_HEIGHT - i]),
        .Q(enq_r[ARRAY_HEIGHT - i - 1])        
      );
  end
endgenerate

// first enq_r signal comes from input port enq
assign enq_r[ARRAY_HEIGHT - 1] = enq;



// connect the mux for the output data
// outputs 0 unless deq signal is active
generate
  for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin
    assign d_out_w[i] = deq_r[i] ? d_out_tmp[i] : {IFMAP_WIDTH {1'b0}};
  end
endgenerate


// assign the enq and deq signal for each fifo
 assign deq_r = en ? empty_n_w : '{ARRAY_HEIGHT {1'b0}};  // when enabled, keep dequeueing until empty



endmodule
