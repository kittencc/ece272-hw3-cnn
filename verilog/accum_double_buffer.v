// Description: double buffer for the accumlated sum and ofmap
//              Different from the general double buffer used for ifmap
//              and weights data, accum double buffer has 1 write port and
//              2 read ports.
//              One read port and one write port uses the same bank to
//              save the partial accum sum output by the MAC array, and to
//              feed the partial sums back to the MAC array.
//              The other port is used to output ofmap data to the
//              testbench from the other bank.
// Author: Cheryl (Yingqiu) Cao
// Date: 2022-01-09


module accum_double_buffer
#( 
  parameter DATA_WIDTH      = 64,     // original data width 16 * chaining_length of 4
  parameter BANK_ADDR_WIDTH = 8,       // width of read/write addr
  parameter MEM_DEPTH       = 256     // capacity of the memory
)(
  input logic clk,
  input logic rst_n,
  input logic switch_banks,

// 1 read 1 write ports for the mac array and the accum sum 
  input logic wen,
  input logic [BANK_ADDR_WIDTH - 1 : 0] waddr,
  input logic [DATA_WIDTH - 1 : 0] wdata,
  input logic ren,
  input logic [BANK_ADDR_WIDTH - 1 : 0] raddr_accum,
  output logic [DATA_WIDTH - 1 : 0] rdata_accum,

// 1 read port to send ofmap data out
  input logic ren_ofmap,
  input logic [BANK_ADDR_WIDTH - 1 : 0] raddr_ofmap,
  output logic [DATA_WIDTH - 1 : 0] rdata_ofmap

);

  // Internally keeps track of which ram is being used for reading and which
  // for writing using some state

  // local signals
  logic ren1, ren2, wen1, wen2;                 // en signal for the two rams
  logic [BANK_ADDR_WIDTH - 1 : 0] raddr1, raddr2;     // read addresses for the two rams
  logic [DATA_WIDTH - 1 : 0] rdata1, rdata2;    // rdata output from the two rams
//  logic [DATA_WIDTH - 1 : 0] r_tmp, r_tmp_ofmap;            // local rdata
  
  logic which_ram;                            // when 0, write to ram1, read ofmap from ram 2
  logic active;
  logic write_active;
  logic read_active, read_active_ofmap;
  logic delayed_read_active, delayed_read_active_ofmap;                // read active delayed by 1 clk cycle (because reading takes 1 cycle)

  assign active = rst_n && (!switch_banks);  // disable both rams during switching
  assign write_active = active && wen;
  assign read_active = active && ren;
  assign read_active_ofmap = active && ren_ofmap;

  // routing the enable signals for the two rams
  assign wen1 = write_active && (!which_ram);
  assign wen2 = write_active && which_ram;
  assign ren1 = which_ram ? read_active_ofmap : read_active;
  assign ren2 = which_ram ? read_active : read_active_ofmap;


  // routing the read_addr to the two rams
  assign raddr1 = which_ram ? raddr_ofmap : raddr_accum;
  assign raddr2 = which_ram ? raddr_accum : raddr_ofmap;

  // routing rdata_ofmap from the two rams
  assign rdata_ofmap = delayed_read_active_ofmap ? ( which_ram ? rdata1 : rdata2 ) : {DATA_WIDTH {1'b0}};

  // routing rdata_accum from the two rams
  assign rdata_accum = delayed_read_active ? ( which_ram ? rdata2 : rdata1 ) : {DATA_WIDTH {1'b0}};



  // logic for delayed_read_active
  always @ (posedge clk) begin
    delayed_read_active <= read_active;
  end

  // logic for delayed_read_active_ofmap
  always @ (posedge clk) begin
    delayed_read_active_ofmap <= read_active_ofmap;
  end


  // determine which ram is at use for read/write
  always @ (posedge clk) begin
    if (!rst_n)
      which_ram <= 1'b0;       // initialize to 0 during reset
    else if (switch_banks)
      which_ram <= ~which_ram;  // flip
    else 
      which_ram <= which_ram;  // hold
  end




  // connect ram1
  ram_sync_1r1w #(
  
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(BANK_ADDR_WIDTH),
    .DEPTH(MEM_DEPTH)
  
  ) ram_inst_1 (
  
    .clk(clk),
    .wen(wen1),
    .wadr(waddr),
    .wdata(wdata),
    .ren(ren1),
    .radr(raddr1),
    .rdata(rdata1)
  
  );


 // connect ram2
  ram_sync_1r1w #(
  
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(BANK_ADDR_WIDTH),
    .DEPTH(MEM_DEPTH)
  
  ) ram_inst_2 (
  
    .clk(clk),
    .wen(wen2),
    .wadr(waddr),
    .wdata(wdata),
    .ren(ren2),
    .radr(raddr2),
    .rdata(rdata2)
  
  );


endmodule
