// Description: double buffer
// Author: Cheryl (Yingqiu) Cao
// Date: 2021-11-28

module double_buffer
#( 
  parameter DATA_WIDTH      = 64,     // original data width 16 * chaining_length of 4
  parameter BANK_ADDR_WIDTH = 8,       // width of read/write addr
  parameter MEM_DEPTH       = 256     // capacity of the memory
)(
  input clk,
  input rst_n,
  input switch_banks,
  input ren,
  input [BANK_ADDR_WIDTH - 1 : 0] radr,
  output [DATA_WIDTH - 1 : 0] rdata,
  input wen,
  input [BANK_ADDR_WIDTH - 1 : 0] wadr,
  input [DATA_WIDTH - 1 : 0] wdata
);

  // Internally keeps track of which ram is being used for reading and which
  // for writing using some state

  // local signals
  logic ren1, ren2, wen1, wen2;                 // en signal for the two rams
  logic [DATA_WIDTH - 1 : 0] rdata1, rdata2;    // rdaa output from the two rams
  logic [DATA_WIDTH - 1 : 0] r_tmp;            // local rdata
  
  logic which_ram;                            // when 0, write to ram1, read from ram 2
  logic active;
  logic write_active;
  logic read_active;
  logic delayed_read_active;                // read active delayed by 1 clk cycle (because reading takes 1 cycle)

  assign active = rst_n && (!switch_banks);  // disable both rams during switching
  assign write_active = active && wen;
  assign read_active = active && ren;

  assign wen1 = write_active && (!which_ram);
  assign wen2 = write_active && which_ram;
  assign ren1 = read_active && (which_ram);
  assign ren2 = read_active && (!which_ram);

  // logic for delayed_read_active
  always @ (posedge clk) begin
    delayed_read_active <= read_active;
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


  // choosing which rdata to direct to the output based on which_ram 
  mux2 #( .DATA_WIDTH(DATA_WIDTH)
  ) mux2_inst_1 (
  
    .sel(which_ram),
    .in1(rdata2),    // select in1 when sel = 0
    .in2(rdata1),
    .out(r_tmp)
  
  );

  // connect output mux for rdata
  // rdata is zero if read_active is low
  mux2 #( .DATA_WIDTH(DATA_WIDTH)
  ) mux2_inst_2 (
  
    .sel(delayed_read_active),
    .in1({DATA_WIDTH {1'b0}}),    // select in1 when sel = 0
    .in2(r_tmp),
    .out(rdata)
  
  );




  // connect ram1
  ram_sync_1r1w #(
  
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(BANK_ADDR_WIDTH),
    .DEPTH(MEM_DEPTH)
  
  ) ram_inst_1 (
  
    .clk(clk),
    .wen(wen1),
    .wadr(wadr),
    .wdata(wdata),
    .ren(ren1),
    .radr(radr),
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
    .wadr(wadr),
    .wdata(wdata),
    .ren(ren2),
    .radr(radr),
    .rdata(rdata2)
  
  );


endmodule
