// Description: chains input_dat along IC0 = 4 before sending to input
// double buffer
// Author: Cheryl (Yingiuq) Cao
// Date: 2021-11-13
// updated on: 2021-12-27


module input_chaining
#(
  parameter IC0 = 4,
  parameter COUNTER_WID = 4

)
(
  input logic [15:0] input_dat,
  input logic        input_vld,
  input logic        clk,
  input logic        rst_n,
  input logic        en_input,

  output logic [16*IC0-1:0] input_dat_chained,
  output logic              done,
  output logic              input_rdy
);


// local signals
logic                     reading;
logic                     en_shifter;
logic                     last_input;
logic [COUNTER_WID-1 : 0] count;  // monitor the # of read in cyclesi

// signals for the chained FFs
logic [15 : 0]            Q  [ IC0-1 : 0];    //  output signal Q for the chained FFs
logic [15 : 0]            D  [ IC0-1 : 0];    




// determine the control signals
assign input_rdy = rst_n && en_input;
assign reading = input_vld && input_rdy;   // reading data ready this cycle, appear at the output next cycle
assign en_shifter = en_input && reading;
assign last_input = (count == (IC0-1));      // the last reading data ready at the input this cycle

// done signal goes high when the chained input appear at the output
always @ (posedge clk) begin
  if (!rst_n)
    done <= 1'b0;
  else if (en_shifter)      // last data gets read
    done <= last_input;
end


// wire up the counter
counter 
#(
  .MAX_COUNT(IC0),
  .COUNTER_WID(COUNTER_WID)
)
counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_shifter),
  .count(count)
);



// input data shifter //
genvar i;

generate
for ( i = 0; i<IC0; i = i+1 ) begin
  if ( i == (IC0-1) ) 
    assign D[i] = input_dat;
  else
    assign D[i] = Q[i+1];
  
  // output data mapping
  assign input_dat_chained[ (i+1)*16-1 : i*16 ] = Q[i];

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
