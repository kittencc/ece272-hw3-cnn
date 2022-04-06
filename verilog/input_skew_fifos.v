// Updated by Cheryl (Yingqiu) Cao
// Updated on 2022-04-05
// Notes: the previous version contains wires/regs. I cleaned them up to
// be logic and removed unnecessary signals.

module input_skew_fifos
#(
  parameter IFMAP_WIDTH = 16,
  parameter ARRAY_HEIGHT = 4
)(
  input logic clk,
  input logic rst_n,
  output logic                             full_n  [ARRAY_HEIGHT - 1 : 0],
  input  logic                             enq     [ARRAY_HEIGHT - 1 : 0],
  input logic signed [IFMAP_WIDTH - 1 : 0]  d_in    [ARRAY_HEIGHT - 1 : 0],
  output logic                              empty_n [ARRAY_HEIGHT - 1 : 0],
  input logic                               deq     [ARRAY_HEIGHT - 1 : 0],
  output logic signed [IFMAP_WIDTH - 1 : 0] d_out   [ARRAY_HEIGHT - 1 : 0]
);

  logic [IFMAP_WIDTH - 1 : 0] d_w   [ARRAY_HEIGHT : 0][ARRAY_HEIGHT - 1 : 0];
  logic                      enq_w [ARRAY_HEIGHT : 0][ARRAY_HEIGHT - 1 : 0];
  logic                      deq_w [ARRAY_HEIGHT - 1 : 0][ARRAY_HEIGHT - 1 : 0];
  logic                      full_n_w [ARRAY_HEIGHT - 1 : 0][ARRAY_HEIGHT - 1 : 0];
  logic                     empty_n_w [ARRAY_HEIGHT - 1 : 0][ARRAY_HEIGHT - 1 : 0];

  genvar y, x;

  generate
    for (y = 0; y < ARRAY_HEIGHT; y = y + 1) begin: row
      for (x = 0; x < y; x = x + 1) begin: col
        if (x == 0) begin
          assign d_w[x][y] = d_in[y];
          assign enq_w[x][y] = enq[y];
          assign full_n[y] = full_n_w[x][y];
        end else begin
          assign enq_w[x][y] = empty_n_w[x - 1][y] && full_n_w[x][y];
        end
        if (x == y - 1) begin
          assign d_out[y] = d_w[x + 1][y];
          assign deq_w[x][y] = deq[y];
          assign empty_n[y] = empty_n_w[x][y];
        end else begin
          assign deq_w[x][y] = empty_n_w[x][y] && full_n_w[x + 1][y];
        end

        fifo #(.DATA_WIDTH(IFMAP_WIDTH), .FIFO_DEPTH(3), .COUNTER_WIDTH(1)) fifo_inst (
          .clk(clk),
          .rst_n(rst_n),
          .d_in(d_w[x][y]),
          .enq(enq_w[x][y]),
          .full_n(full_n_w[x][y]),
          .d_out(d_w[x + 1][y]),
          .deq(deq_w[x][y]),
          .empty_n(empty_n_w[x][y]),
          .clr(1'b0) 
        );
      end
    end
  endgenerate
  
  assign full_n[0] = deq[0];
  assign empty_n[0] = enq[0];
  assign d_out[0] = d_in[0];
endmodule
