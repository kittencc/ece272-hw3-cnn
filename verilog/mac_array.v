// Description: the parameterized mac array
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-02
// Updated on: 2022-04-10 : data needs to be signed to compute neg values


module mac_array
# (
  parameter IC0 = 4,        // height of the mac array
  parameter OC0 = 4         // width of the mac array
)
(
  input logic  clk,
  input logic  rst_n,
  input logic  en,            // en for the entire mac array
  input logic  en_weight [IC0 - 1 : 0][OC0 - 1 : 0],     // en_weight signal for each mac cell

  input logic [16*OC0 - 1 : 0] weight_dat_chained,
  input logic [16*IC0 - 1 : 0] ifmap_dat_chained,
  input logic [32*OC0 - 1 : 0] accum_in_chained,
  output logic [32*OC0 - 1 : 0] accum_out_chained
 
);

// local signals ++
  logic signed [15 : 0] ifmap_in  [IC0 - 1 : 0][OC0 - 1 : 0];
  logic signed [15 : 0] weight_in [IC0 - 1 : 0][OC0 - 1 : 0];
  logic signed [31 : 0] accum_in  [IC0 - 1 : 0][OC0 - 1 : 0];
  logic signed [15 : 0] ifmap_out [IC0 - 1 : 0][OC0 - 1 : 0];
  logic signed [31 : 0] accum_out [IC0 - 1 : 0][OC0 - 1 : 0];
// local signals --


genvar i,j;
// connect the mac cells together
generate
  for (i = 0; i < IC0; i = i + 1) begin: row
    for (j = 0; j < OC0; j = j + 1 ) begin: col

     // connection for ifmap_in
     if (j == 0) begin
        assign ifmap_in[i][j] = ifmap_dat_chained[16 * (i+1) - 1 : 16 * i];
      end else begin
        assign ifmap_in[i][j] = ifmap_out[i][j-1];
      end

      // connection for weight_in
      // all mac cell in the same column connected to the same weight_in
      assign weight_in[i][j] = weight_dat_chained[16 * (j+1) - 1 : 16 * j];

      // connection for accum_in
      if (i == 0)
        assign accum_in[i][j] = accum_in_chained[32 * (j+1) - 1 : 32 * j];
      else
        assign accum_in[i][j] = accum_out[i-1][j];     

      // connection for accum_out
      if (i == (IC0 - 1))
        assign accum_out_chained[32 * (j+1) - 1 : 32 * j] = accum_out[i][j];

      // connect each mac cell
      mac mac_inst
      (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),            // en for the entire mac module
        .en_weight(en_weight[i][j]),     // en signal for the weight FF
        .ifmap_in(ifmap_in[i][j]),
        .weight_in(weight_in[i][j]),
        .accum_in(accum_in[i][j]),
        .ifmap_out(ifmap_out[i][j]),
        .accum_out(accum_out[i][j])
      );
   
    end
  end
endgenerate



endmodule
