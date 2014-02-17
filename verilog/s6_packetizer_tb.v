`timescale 1ns/1ps

module s6_packetizer_tb;

parameter NWORDS = 128;

localparam NWORDS_BITS = $clog2(NWORDS);

// Drive DUT inputs
reg clk;
reg sync;
reg [63:0] din;
reg [NWORDS_BITS-1:0] start_word;
reg [NWORDS_BITS-1:0] nwords_per_pkt;
reg [3:0] src_id;

// Driven by DUT outputs
wire [63:0] dout;
wire dv;
wire [3:0] dst;
wire eof;

initial begin
  clk = 1'b1;
  sync = 1'b0;
  din = 1'b0;
  start_word = 5'd7;
  nwords_per_pkt = 5'd3;
  src_id = 0;
end

s6_packetizer #(
  .NWORDS(NWORDS)
) dut (
  .clk(clk),
  .ce(1'b1),
  .sync(sync),
  .din(din),
  .start_word(start_word),
  .nwords_per_pkt(nwords_per_pkt),
  .src_id(src_id),
  .dout(dout),
  .dv(dv),
  .dst(dst),
  .eof(eof)
);

always
  #0.5 clk = !clk;

initial 
 #1000  $finish; 

initial begin
  $dumpfile("s6_packetizer_tb.vcd");
  $dumpvars;
end

always @(posedge clk) begin
  sync <= $time == 4;

  if(sync == 1'b1 || din == NWORDS-1)
    din <= 64'b0;
  else
    din <= din + 1;
end

endmodule
