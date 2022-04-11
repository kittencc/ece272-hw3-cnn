// Descrption: connects the mac array with the skew_fifos for ifmap,
// weights and ofmap, and the en_weight_shifter module
// Author: Cheryl (Yingqiu) Cao
// Date: 2020-04-10

module mac_more
# (
  parameter IC0 = 4,        // height of the mac array
  parameter OC0 = 4         // width of the mac array

)
(
  input logic  clk,
  input logic  rst_n,
  input logic  en,            // en for the entire mac array
  input logic  en_weight00,   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
  input logic ifmap_fifo_enq,
  input logic [16*IC0 - 1 : 0] ifmap_dat_chained_fifo_in,
  input logic weight_fifo_enq,
  input logic [16*OC0 - 1 : 0] weight_dat_chained_fifo_in,
  input logic accum_in_fifo_enq,
  input logic [32*OC0 - 1 : 0] accum_in_chained_fifo_in,
  input logic accum_out_fifo_enq,
  output logic [32*OC0 - 1 : 0] accum_out_chained_fifo_out

);

// local signals ++
  // for mac_array
  logic  en_weight [IC0 - 1 : 0][OC0 - 1 : 0];     // en_weight signal for each mac cell

  // for ifmap_skew_fifo
  logic [16*IC0 - 1 : 0] ifmap_dat_chained_fifo_out;
  logic signed [15 : 0] ifmap_d_in_r [IC0 - 1 : 0];
  logic signed [15 : 0] ifmap_d_out_w [IC0 - 1 : 0];

  // for weight_skew_fifo
  logic [16*OC0 - 1 : 0] weight_dat_chained_fifo_out;
  logic signed [15 : 0] weight_d_in_r [OC0 - 1 : 0];
  logic signed [15 : 0] weight_d_out_w [OC0 - 1 : 0];


  // for accum_in_skew_fifo
  logic [32*OC0 - 1 : 0] accum_in_chained_fifo_out;
  logic signed [31 : 0] accum_in_d_in_r [OC0 - 1 : 0];
  logic signed [31 : 0] accum_in_d_out_w [OC0 - 1 : 0];


  // for accum_out_skew_fifo
  logic [32*OC0 - 1 : 0] accum_out_chained_fifo_in;
  logic signed [31 : 0] accum_out_d_in_r [OC0 - 1 : 0];
  logic signed [31 : 0] accum_out_d_out_w [OC0 - 1 : 0];


// local signals --


// wire-up the mac_array module
mac_array
# (
  .IC0(IC0),        // height of the mac array
  .OC0(OC0)         // width of the mac array
)
mac_array_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),            // en for the entire mac array
  .en_weight(en_weight),     // en_weight signal for each mac cell
  .weight_dat_chained(weight_dat_chained_fifo_out),
  .ifmap_dat_chained(ifmap_dat_chained_fifo_out),
  .accum_in_chained(accum_in_chained_fifo_out),
  .accum_out_chained(accum_out_chained_fifo_in)
 
);



// wire-up the en_weight_shifter module
en_weight_shifter
# (
  .IC0(IC0),        // height of the mac array
  .OC0(OC0)         // width of the mac array
) 
en_weight_shifter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .en_weight00(en_weight00),
  .en_weight(en_weight)
);



// wire-up the ifmap skew_fifo
wrapped_skew_fifo
# (
  .IFMAP_WIDTH(16),
  .ARRAY_HEIGHT(IC0)
) 
ifmap_skew_fifo_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .enq(ifmap_fifo_enq),
  .d_in_r(ifmap_d_in_r),
  .d_out_w(ifmap_d_out_w)
);


// wire-up the weight skew_fifo
wrapped_skew_fifo
# (
  .IFMAP_WIDTH(16),
  .ARRAY_HEIGHT(OC0)
) 
weight_skew_fifo_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .enq(weight_fifo_enq),
  .d_in_r(weight_d_in_r),
  .d_out_w(weight_d_out_w)
);



// wire-up the accum_in skew_fifo
wrapped_skew_fifo
# (
  .IFMAP_WIDTH(32),
  .ARRAY_HEIGHT(OC0)
) 
accum_in_skew_fifo_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .enq(accum_in_fifo_enq),
  .d_in_r(accum_in_d_in_r),
  .d_out_w(accum_in_d_out_w)
);



// wire-up the accum_out skew_fifo
wrapped_skew_fifo
# (
  .IFMAP_WIDTH(32),
  .ARRAY_HEIGHT(OC0)
) 
accum_out_skew_fifo_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en),
  .enq(accum_out_fifo_enq),
  .d_in_r(accum_out_d_in_r),
  .d_out_w(accum_out_d_out_w)
);




genvar i;

// generate statements to connect data wires for ifmap
generate
 for (i = 0; i < IC0; i = i + 1) begin
   assign ifmap_d_in_r[i] = ifmap_dat_chained_fifo_in[16*(i+1) - 1 : 16*i];
   assign ifmap_dat_chained_fifo_out[16*(i+1) - 1 : 16*i] = ifmap_d_out_w[i];
 end
endgenerate


// generate statements to connect data wires for weight
generate
 for (i = 0; i < OC0; i = i + 1) begin
   assign weight_d_in_r[i] = weight_dat_chained_fifo_in[16*(i+1) - 1 : 16*i];
   assign weight_dat_chained_fifo_out[16*(i+1) - 1 : 16*i] = weight_d_out_w[i];
 end
endgenerate

// generate statements to connect data wires for accum_in
generate
 for (i = 0; i < OC0; i = i + 1) begin
   assign accum_in_d_in_r[i] = accum_in_chained_fifo_in[32*(i+1) - 1 : 32*i];
   assign accum_in_chained_fifo_out[32*(i+1) - 1 : 32*i] = accum_in_d_out_w[i];
 end
endgenerate

// generate statements to connect data wires for accum_out
// note the different order of indexing!!
generate
 for (i = 0; i < OC0; i = i + 1) begin
   assign accum_out_d_in_r[OC0-1 - i] = accum_out_chained_fifo_in[32*(i+1) - 1 : 32*i];
   assign accum_out_chained_fifo_out[32*(i+1) - 1 : 32*i] = accum_out_d_out_w[OC0-1 - i];
 end
endgenerate


endmodule
