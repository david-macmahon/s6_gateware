`timescale 1ns/1ps

module crc32x64_tb;

// Drive DUT inputs
reg         clk;
reg         valid_in;
reg         init_in;
reg  [63:0] data_in;

// Driven by DUT outputs
wire        valid_out;
wire        init_out;
wire [63:0] data_out;
wire [31:0] crc;

crc32x64 dut (
  .clk(clk),
  .ce(1'b1),
  .valid_in(valid_in),
  .init_in(init_in),
  .data_in(data_in),
  .valid_out(valid_out),
  .init_out(init_out),
  .data_out(data_out),
  .crc(crc)
);

initial begin
  clk = 0;
  valid_in = 0;
  init_in = 0;
  data_in = 0;
end

always
  #0.5 if($realtime>0.5) clk = !clk;

initial begin
  $dumpfile("crc32x64.vcd");
  $dumpvars;
end

initial  begin
  $display("time  vin  init_i  data_i            vout  init_o  data_o              crc");
  $monitor("%4d   %b     %b     %x   %b      %b     %x    %x",
    $time, valid_in, init_in, data_in, valid_out, init_out, data_out, crc);
end

initial
 #25  $finish;

always @(posedge clk) begin
  data_in <= data_in + 1;
  init_in <= (data_in % 5 == 1) ? 1 : 0;
  valid_in <= data_in[1];
end

endmodule
