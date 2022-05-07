// Description: parallel in series out
// The output from MAC array was chained along OC0 = 4
// We need to unchain the ofmap output data to send them to the CNN
// testbench through the serial bus.
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-17
// Updated on 2022-05-07: counter module was updated

module ofmap_PISO
# (
  parameter OC0 = 4,
  parameter COUNTER_WID = 4

)
(
  input logic clk,
  input logic rst_n,

  // control signals
  input logic en_PISO,
  input logic load,        // load chained data into internal ffs
  input logic start,       // sel signal for the shifter's input mux, loads chained data into the shifter 
  output logic chaining_last_one,          // output to the FSM

  // data
  input logic [32*OC0 - 1 : 0] ofmap_dat_chained,
  input logic ofmap_rdy,
  output logic [31 : 0] ofmap_dat,
  output logic ofmap_vld
);


// local signals
logic ready_to_unchain;
logic en_shifter;
logic [COUNTER_WID-1 : 0] count;          // monitor the # of data getting unchained
logic [32*OC0 - 1 : 0] Q_dat_chained;     // local copy of the chained data. Making a copy so that the input chained_data only needs to stay valid for one clk cycle
logic [COUNTER_WID-1 : 0] config_MAX_COUNT;  // counter counts to config_MAX_COUNT - 1

// signals for the chained FFs
logic [31 : 0]   Q  [ OC0-1 : 0];    //  output signal Q for the chained FFs
logic [31 : 0]   D  [ OC0-1 : 0];  
// signals for the mux 
logic [31 : 0]  mux_in2  [ OC0-1 : 0];    // input signal for the muxes
logic [31 : 0]  mux_in1  [ OC0-1 : 0];    


// assignment of local signals
assign ready_to_unchain = ofmap_rdy;
assign en_shifter = en_PISO && ready_to_unchain;


// assign output chaining_last_one
assign chaining_last_one = en_shifter && (count == (OC0-1));

// set the MAX_COUNTER for the counter
assign config_MAX_COUNT = OC0;


// logic for ofmap_vld
// ofmap_vld is en_shifter delayed by 1 clk cycle
always @ (posedge clk) begin
  if (!rst_n)
    ofmap_vld <= 1'b0;
  else 
    ofmap_vld <= en_shifter;
end


// connect the chaining counter
// counts the current # of data getting unchained
counter 
#(
  .COUNTER_WID(COUNTER_WID)
)
counter_inst
(
  .clk(clk),
  .rst_n(rst_n),
  .en(en_shifter),
  .count(count),
  .config_MAX_COUNT(config_MAX_COUNT)
);



// connect the ff for ofmap_dat_chained
  ff #(.DATA_WIDTH(32*OC0)) 
  ff_chained_dat
  (
  .rst_n(rst_n),
  .en(load),
  .clk(clk),
  .D(ofmap_dat_chained),
  .Q(Q_dat_chained)        
  );




// construct the shifter
genvar i;

generate
for ( i = 0; i < OC0; i = i + 1 ) begin

  // assign ofmap_dat
  if (i == 0)
    assign ofmap_dat = Q[i];

  // data mapping for mux_in
  assign mux_in2[i] = Q_dat_chained[(i+1)*32-1 : i*32];

  if (i == (OC0-1))
    assign mux_in1[i] = {32 {1'b0}};
  else
    assign mux_in1[i] = Q[i+1];


  // wire up the FFs
  ff #(.DATA_WIDTH(32)) ff_inst
  (
      .rst_n(rst_n),
      .en(en_shifter),
      .clk(clk),
      .D(D[i]),
      .Q(Q[i])        // ic0 data saves at the low end. e.g. {ifmap_IC3, ifmap_IC2, ifmap_IC1, ifmap_IC0}
    );

  // wire up the muxes
mux2 #(.DATA_WIDTH(32)) mux_inst
(
  .sel(start),
  .in1(mux_in1[i]),    
  .in2(mux_in2[i]),
  .out(D[i])
);


end
endgenerate


endmodule
