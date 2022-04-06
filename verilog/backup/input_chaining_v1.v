// Description: chains ifmap_data along IC0 = 4 before sending to input
// double buffer
// Author: Cheryl (Yingiuq) Cao
// Date: 2021-11-07


module input_chaining
#(
  parameter IC0 = 4
)
(
  input logic [15:0] ifmap_dat,
  input logic        ifmap_vld,
  input logic        clk,
  input logic        rst_n,
  input logic        en_input,

  output logic [16*IC0-1:0] ifmap_dat_chained,
  output logic              done,
  output logic              ifmap_rdy
);

// local signals
logic en_shifter;
logic rst_sh_n;          // rst signal for the shifter
logic reading;          // is 1 if current cycle is reading ifmap_dat
logic en_i [IC0-1:0];    // D input to the shifter
logic en   [IC0-1:0];    // Q output from the shifter ff
logic en_f [IC0-1:0];    // final enable signal for the data ffs
logic in1  [IC0-1:0];    // in1 for the mux 
logic in2  [IC0-1:0];    // in2 for the mux 


// determine the control signals
assign ifmap_rdy = rst_n && en_input;
assign reading = ifmap_rdy && ifmap_vld; 
assign en_shifter = reading || !rst_sh_n; // only enables when you are reading a data the begging ofnext cyclee

// rst_sh_n is rst_n delayed by 1 cycle
// rst_sh_n changes at negtive clk edge
always @ ( negedge clk ) begin
  rst_sh_n <= rst_n;
end


// done is en_f[last] delayed by 1 cycle
//  done goes high when the chained data appears at the output
always @ ( posedge clk ) begin
  done <= en_f[IC0-1];
end




genvar i;

// generate the shifter for the en signal
generate
  for ( i=0; i<IC0; i=i+1 ) begin
    if (i==0) begin
        // mux signals
        assign in1[i] = 1'b1;
        assign in2[i] = en[IC0-1];
    end
    else begin
      // mux signals
      assign in1[i] = 1'b0;
      assign in2[i] = en[i-1];
    end
  
   // connect the mux
    mux2 #(.DATA_WIDTH(1)) mux2_inst(
      .sel(rst_sh_n),
      .in1(in1[i]),
      .in2(in2[i]),
      .out(en_i[i])
    );

    // connect the ffs
    ff #(.DATA_WIDTH(1)) ff_inst(
      .rst_n(rst_n),
      .en(en_shifter),
      .clk(clk),
      .D(en_i[i]),
      .Q(en[i])
    );

  end 
endgenerate


// generate the data chaining 
generate
  for ( i = 0; i< IC0; i = i+1 ) begin
    // and gate for the enable signal
    assign en_f[i] = en[i] && reading;

    // connect the data ffs
    ff #(.DATA_WIDTH(16)) ff_inst(
      .rst_n(rst_n),
      .en(en_f[i]),
      .clk(clk),
      .D(ifmap_dat),
      .Q( ifmap_dat_chained[ (i+1)*16-1 : i*16] )        // ic0 data saves at the low end. e.g. {ifmap_IC3, ifmap_IC2, ifmap_IC1, ifmap_IC0}
    );

  end
endgenerate

endmodule
