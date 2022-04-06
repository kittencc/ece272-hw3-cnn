// Description: chains weight_dat along OC0 = 4 before sending to weight
// double buffer
// Author: Cheryl (Yingiuq) Cao
// Date: 2021-11-13
// updated on: 2021-12-27


module weights_chaining
#(
  parameter OC0 = 4,
  parameter COUNTER_WID = 4

)
(
  input logic [15:0] weights_dat,
  input logic        weights_vld,
  input logic        clk,
  input logic        rst_n,
  input logic        en_input,

  output logic [16*OC0-1:0] weights_dat_chained,
  output logic              done,
  output logic              weights_rdy
);


// local signals
logic                     reading;
logic                     en_shifter;
logic                     last_weight;
logic [COUNTER_WID-1 : 0] count;  // monitor the # of read in cyclesi

// signals for the chained FFs
logic [15 : 0]            Q  [ OC0-1 : 0];    //  output signal Q for the chained FFs
logic [15 : 0]            D  [ OC0-1 : 0];    




// determine the control signals
assign weights_rdy = rst_n && en_input;
assign reading = weights_vld && weights_rdy;   // reading data ready this cycle, appear at the output next cycle
assign en_shifter = en_input && reading;
assign last_weight = (count == (OC0-1));      // the last reading data ready at the input this cycle

// done signal goes high when the chained weight appear at the output
always @ (posedge clk) begin
  if (!rst_n)
    done <= 1'b0;
  else if (en_shifter)      // last data gets read
    done <= last_weight;
end


// wire up the counter
counter 
#(
  .MAX_COUNT(OC0),
  .COUNTER_WID(COUNTER_WID)
)
counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_shifter),
  .count(count)
);



// weight data shifter //
genvar i;

generate
for ( i = 0; i<OC0; i = i+1 ) begin
  if ( i == (OC0-1) ) 
    assign D[i] = weights_dat;
  else
    assign D[i] = Q[i+1];
  
  // output data mapping
  assign weights_dat_chained[ (i+1)*16-1 : i*16 ] = Q[i];

  // wire up the FFs
  ff #(.DATA_WIDTH(16)) ff_inst(
      .rst_n(rst_n),
      .en(en_shifter),
      .clk(clk),
      .D(D[i]),
      .Q(Q[i])        // ic0 data saves at the low end. e.g. {ifmap_IC3, ifmap_IC2, ifmap_IC1, ifmap_IC0}
    );


end
endgenerate

endmodule
