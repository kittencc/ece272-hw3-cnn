// Description: wrapped version of input_skew_fifo.v to customize the
// connection of some IO ports
//    - add an en signal: when enabled, each row outputs one data per
//                        cycle until empty
//    - one enq signal for the entire module: input for the fifo rows arrive
//                        at the same time from double buffer
//    - remove deq[i]:     derive it from other signals
//    Author: Cheryl (Yingqiu) Cao
//    Date: 2022-04-09
//    Updated on: 2020-04-10: output dat needs to be 0 when NOT dequeueing
//                for the correction computation of the mac_array

module wrapped_skew_fifo
# (
  parameter IFMAP_WIDTH = 16,
  parameter ARRAY_HEIGHT = 4
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


// connect input_skew_fifos
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

genvar i;
// connect the mux for the output data
generate
  for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin
    assign d_out_w[i] = deq_r[i] ? d_out_tmp[i] : {IFMAP_WIDTH {1'b0}};
  end
endgenerate

// assign the enq and deq signal for each fifo
 assign enq_r = en ? '{ARRAY_HEIGHT {enq}} : '{ARRAY_HEIGHT {1'b0}};
 assign deq_r = en ? empty_n_w : '{ARRAY_HEIGHT {1'b0}};  // when enabled, keep dequeueing until empty

endmodule
