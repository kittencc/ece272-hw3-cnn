// Description: testbench for conv_tiled.v
//              - just directly feeds the ifmap/weight data
//              - OY0 = OX0 = 3, OC0 = IC0 = 4, FY = FX = 3
//              - ifmap/weight array contains negative numbers
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-08-01

module simple_tb_3;

// local parameters ++
  localparam PARAM_NUM = 6;
  localparam PARAM_WID = 16;
  localparam BANK_ADDR_WIDTH = 32;       // width needed to save IC1*IX0*IY0, OY1_OX1
  localparam BUFFER_MEM_DEPTH = 512;     // capacity of the memory, larger
 //  than IC1*Ix0*IY0 (ifmap), FX*FY*IC*OC1 (weight double buffer), and
 //  OX0*OY0 (ofmap)

//  cnn parameters
  localparam OY0 = 3;
  localparam OX0 = 3;
  localparam OC0 = 4;
  localparam IC0 = 4;
  localparam Stride = 1;

// parameters on: input data dimensions
  localparam OY = 12;
  localparam OX = 12;
  localparam OC = 16;
  localparam IC = 8;
  localparam FY = 3;
  localparam FX = 3;

// derived parameters
  localparam OY1 = OY / OY0;
  localparam OX1 = OX / OX0;
  localparam OC1 = OC / OC0;
  localparam IC1 = IC / IC0;
  localparam IX = (OX - 1) * Stride + FX;
  localparam IY = (OY - 1) * Stride + FY;
  localparam IX0 = (OX0 - 1) * Stride + FX;
  localparam IY0 = (OY0 - 1) * Stride + FY;

  // array size for ifmap/weight/ofmap, when flattening the
  // multi-dimensional array into a vector
  localparam IFMAP_SIZE =  OY1 * OX1* IC1 * IY0 * IX0 * IC0;
  localparam WEIGHT_SIZE = FX * FY * IC * OC;
  localparam OFMAP_SIZE = OX * OY * OC;

  // local parameters --



// local signals ++
  logic clk;
  logic rst_n;

  // ifmap
  logic [15:0] ifmap_dat;
  logic ifmap_rdy;
  logic ifmap_vld;

  // weights
  logic [15:0] weights_dat;
  logic weights_rdy;
  logic weights_vld;

  // ofmap
  logic [31:0] ofmap_dat;
  logic ofmap_rdy;
  logic ofmap_vld;

  // params
  logic [ PARAM_NUM * PARAM_WID - 1 : 0] layer_params_dat;  // {OY1, OC1, IC1, FY, OY0, stride}
  logic layer_params_rdy;
  logic layer_params_vld;

  // saves the full data matrices
  logic [ PARAM_NUM * PARAM_WID - 1 : 0] params;  // {OY1, OC1, IC1, FY, OY0, stride}
  logic [15:0] ifmap_dat_full   [IFMAP_SIZE - 1 : 0];
  logic [15:0] weights_dat_full [WEIGHT_SIZE - 1 : 0];
  logic [31:0] ofmap_dat_full   [OFMAP_SIZE - 1 : 0];

// local signals --





// clk
always #10 clk = ~clk;  // clk cycle is 20


/* layer params assignment */
assign params = {OY1[PARAM_WID - 1 : 0], OC1[PARAM_WID - 1 : 0], IC1[PARAM_WID - 1 : 0], FY[PARAM_WID - 1 : 0], OY0[PARAM_WID - 1 : 0],
Stride[PARAM_WID - 1 : 0]};

/*          connect the dut            */
conv_tiled
#(
  .IC0(IC0),
  .OC0(OC0),
  .PARAM_NUM(PARAM_NUM),
  .PARAM_WID(PARAM_WID),
  .BANK_ADDR_WIDTH(BANK_ADDR_WIDTH),
  .BUFFER_MEM_DEPTH(BUFFER_MEM_DEPTH)
)
dut
(
  .clk(clk),
  .rst_n(rst_n),
  .ifmap_dat(ifmap_dat),
  .ifmap_rdy(ifmap_rdy),
  .ifmap_vld(ifmap_vld),
  .weights_dat(weights_dat),
  .weights_rdy(weights_rdy),
  .weights_vld(weights_vld),
  .ofmap_dat( ofmap_dat),
  .ofmap_rdy(ofmap_rdy),
  .ofmap_vld(ofmap_vld),
  .layer_params_dat(layer_params_dat),
  .layer_params_rdy(layer_params_rdy),
  .layer_params_vld(layer_params_vld)
);


// local variables only for the initial block//
  // index to read the layer_param/ifmap/weight array data
  logic params_write;  // declares outside
  int ifmap_idx;
  int weights_idx;
  int ofmap_idx;

initial begin

  // reads ifmap/weight data from files
  $readmemh("data/layer6_ifmap.mem", ifmap_dat_full);
  $readmemh("data/layer6_weights.mem", weights_dat_full);


  // initialize the index to 0
  ifmap_idx = 0;
  weights_idx = 0;
  ofmap_idx = 0;
  params_write = 0;

  // start w/ a reset signal
  clk = 0;
  rst_n = 0;

  # 20    // reset goes high
  rst_n = 1;
  // ofmap always ready
  ofmap_rdy = 1;


  while(ifmap_idx < IFMAP_SIZE || weights_idx < WEIGHT_SIZE ||
  params_write == 0 || ofmap_idx < OFMAP_SIZE) begin

    # 20   // let 1 clk cycle pass

    if ((ifmap_idx < IFMAP_SIZE) && ifmap_rdy ) begin
      ifmap_dat = ifmap_dat_full[ifmap_idx];
      ifmap_vld = 1;
      ifmap_idx = ifmap_idx + 1;
    end
    else begin
      ifmap_vld = 0;
    end

    if ((weights_idx < WEIGHT_SIZE) && weights_rdy) begin
      weights_dat = weights_dat_full[weights_idx];
      weights_vld = 1;
      weights_idx = weights_idx + 1;
    end
    else begin
      weights_vld = 0;
    end

    if(ofmap_idx < OFMAP_SIZE && ofmap_vld == 1) begin
      ofmap_dat_full[ofmap_idx] = ofmap_dat;
      ofmap_rdy = 1;
      ofmap_idx = ofmap_idx + 1;
    end


    if(params_write == 0 && layer_params_rdy) begin
      layer_params_dat = params;
      layer_params_vld = 1;
      params_write = 1;
    end
    else begin
      layer_params_vld = 0;
    end

  end



end


// to display the waveforms for debugging
// saves waveform to dsfb for verdi to open
initial begin
  $fsdbDumpfile("dump.fsdb");
  $fsdbDumpvars(0, simple_tb_3);
  $fsdbDumpMDA(0, simple_tb_3);
  #500000;
  $finish;
end



endmodule
