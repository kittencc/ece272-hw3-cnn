// Description: derive en_weight[x][y] signal for each mac cell
//              from a global en_weight00 signal from the mac array
//              Basically, in the top module, we only need to set
//              en_weight00, and the en_weight[x][y] will propagate based
//              on shifters defined here.
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-04-09

module en_weight_shifter
# (
  parameter IC0 = 4,        // height of the mac array
  parameter OC0 = 4         // width of the mac array
)
(
  input logic  clk,
  input logic  rst_n,
  input logic  en,            // en for the entire mac array
  input logic  en_weight00,   // en_weight signal for the first mac cell ic0 = 0, oc0 = 0
  output logic  en_weight [IC0 - 1 : 0][OC0 - 1 : 0]     // en_weight signal for each mac cell
);

// local signals
// for the shifted implemented by chained FFs
//logic D [IC0 - 2 : 0][OC0 - 1 : 0];
//logic Q [IC0 - 2 : 0][OC0 - 1 : 0];

// construct the shifter
genvar i, j;

generate
  for (i =  1; i < IC0; i = i + 1) begin: row
    for (j = 0; j < OC0; j = j + 1) begin: col
      // assignment for D[i][j]
      if ( i == 1 ) begin
        if ( j == 0 )
          assign en_weight[i-1][j] = en_weight00;
        else
          assign en_weight[i-1][j] = en_weight[i][j-1];
      end

      // connect the FFs
      ff #(.DATA_WIDTH(1)) ff_inst
      (
        .rst_n(rst_n),
        .en(en),
        .clk(clk),
        .D(en_weight[i-1][j]),
        .Q(en_weight[i][j])        
      );

    end
  end
endgenerate




endmodule
