`timescale 1ns/1ps

// s6_packetizer is a packetizer for the SERENDIP 6 spectrometer.

// * Parameters:
//   - NWORDS Number of words per spectrum.
//
// * Inputs
//   - clk:            Clock to drive logic.
//   - ce:             Clock enable (currently ignored).
//   - sync:           Goes high one cycle before channel 0 appears on `data`.
//                     Resets `mcnt` counter.
//   - din:            Spectral data, two 8+8 complex channels (chan 2*n and
//                     2*n+1) for two signals. {I0C0, I0C1, I1C0, I1C1}
//   - start_word:     Starting channel number (lsb is ignored, i.e. masked to 0).
//   - nwords_per_pkt: Number of channels per packet. (lsb is ignored, i.e. masked
//                     to 0).
//   - src_id:         ID of this packetizer.  Each packetizer will has an ID
//                     field that is included in the packet header to indicate
//                     which packetizer generated the packet.
//
// * Outputs
//   - dout: Packet data suitable for streaming into CASPER 10 GbE block.
//   - dv: Data valid suitable for streaming into CASPER 10 GbE block.
//   - dst: Destination ID (0-7) (useful for constructing dest IP).
//   - eof: End of frame suitable for streaming into CASPER 10 GbE block.
//
// * Packet format
//
//     HEADER
//     DATA(0)
//     DATA(1)
//     DATA(2)
//     ...
//     DATA(nwords_per_pkt-1)
//     CRC
//
//  Note that CRC is just a placeholder for the CRC.  It is is filled 64 1 bits.
//
// * Header format (for NWORDS=2048)
// 
//     {scount[47:0}, {word[10:0], 1'b0}, src_id[3:0]}
//

module s6_packetizer
#(
  parameter integer NWORDS = 2048
)
(
  input clk,
  input ce,
  input sync,
  input [63:0] din,
  input [NWORDS_BITS-1:0] start_word,
  input [NWORDS_BITS-1:0] nwords_per_pkt,
  input [3:0] src_id,
  output reg [63:0] dout,
  output reg dv,
  output reg [3:0] dst,
  output reg eof
);

localparam NWORDS_BITS = $clog2(NWORDS);

// The safe minimum for DATABUF_DEPTH is at most 2/3 NWORDS, but since that is
// more than half we are setting it equal to NWORDS (for now).
localparam DATABUF_DEPTH = NWORDS;
localparam DATABUF_DEPTH_BITS = $clog2(NWORDS);

localparam CRC_LATENCY = 7;

reg [NWORDS_BITS-1:0] stop_word = 1'b0;
reg [NWORDS_BITS-1:0] word_count = 1'b0;
reg [64-(NWORDS_BITS+1)-4-1:0] mcount = 1'b0;
reg [64-(NWORDS_BITS+1)-4-1:0] mcount_out = 1'b0;
reg [NWORDS_BITS-1:0] pkt_start_word = 1'b0;
reg [NWORDS_BITS-1:0] pkt_stop_word = 1'b0;
reg [3:0] src_id_out = 0;

reg [63:0] din_reg;

reg [63:0] dout_int;
reg        dv_int;
reg [ 3:0] dst_int, dst_pipeline[CRC_LATENCY-1:0], dst_delay;
reg        eof_int, eof_pipeline[CRC_LATENCY-1:0];
reg        sof_int;

wire [63:0] dout_crc;
wire dv_crc;
wire [31:0] crc_crc;
reg  [31:0] crc_crc1;

// Data buffer is 64 bits wide
reg [63:0] databuf[DATABUF_DEPTH-1:0];

reg databuf_we = 1'b0;
reg [DATABUF_DEPTH_BITS-1:0] wr_addr = 1'b0;
reg [DATABUF_DEPTH_BITS-1:0] rd_addr = 1'b0;

// Output state machine
localparam IDLE   = 2'b00;
localparam HEADER = 2'b01;
localparam DATA   = 2'b10;
localparam CRC    = 2'b11;
reg [1:0] state = IDLE;

reg [NWORDS_BITS-1:0] pkt_word_count = 1'b0;
reg [2:0] oe_shift_reg = 3'b011;
wire oe;

// General purpose loop variable
integer i;

// Initialize data buffer for simulation (and FPGA?)
initial begin
  for(i=0; i<DATABUF_DEPTH; i=i+1)
    databuf[i] = 0;
  dout_int <= 64'b0;
  dv_int <= 1'b0;
  dst_int <= 4'h0;
  eof_int <= 1'b0;
  dout <= 64'b0;
  dv <= 1'b0;
  dst <= 4'h0;
  eof <= 1'b0;
end

// Word_count and mcount
always @(posedge clk) begin
  if(sync == 1'b1) begin
    // Reset
    word_count <= 0;
    mcount <= 0;
  end else if(word_count == NWORDS-1) begin
    // Roll over word_count, increment mcount
    word_count <= 1'b0;
    mcount <= mcount + 1;
  end else begin
    // increment word_count
    word_count <= word_count + 1;
  end
end

// Pipelined calculations of stop_word and pkt_stop_word.
// These are expected to change very infrequently.
always @(posedge clk) begin
  stop_word <= start_word + (nwords_per_pkt<<3);
  pkt_stop_word <= nwords_per_pkt - 1;
end

// Data buffer write enable logic
always @(posedge clk) begin
  if(sync == 1) begin
    wr_addr <= 0;
    databuf_we <= 0;
  end else begin
    if(word_count == start_word)
      databuf_we <= 1;
    if(word_count == stop_word) begin
      databuf_we <= 0;
      wr_addr <= 0;
    end
  end
end

// Data buffer write logic
always @(posedge clk) begin
  din_reg <= din; // Delay din
  if(databuf_we == 1) begin
    databuf[wr_addr] <= din_reg;
    wr_addr <= wr_addr + 1;
  end
end

// Data output enable generator
always @(posedge clk) begin
  if(sync == 1)
    oe_shift_reg <= 3'b011;
  else
    // Rotate bits
    oe_shift_reg <= {oe_shift_reg[0], oe_shift_reg[2:1]};
end
assign oe = oe_shift_reg[0];

// Output FSM state transition logic
always @(posedge clk) begin
  // DV and DST are 0 unless explicitly set to 1
  dv_int <= 0;
  sof_int <= 0;
  eof_int <= 0;

  if(sync == 1) begin
    // Reset
    state <= IDLE;
    rd_addr <= 0;
    pkt_start_word <= 0;
    pkt_word_count <= 0;
  end else begin
    // State transition
    case(state)
      IDLE: begin
        if(word_count == start_word) begin
          // Register mcount and sc_id so that they will not change on us
          // during this output cycle.
          mcount_out <= mcount;
          src_id_out <= src_id;
          pkt_start_word <= start_word;
          state <= HEADER;
        end
      end
      HEADER: begin
        // Drive outputs
        sof_int <= 1;
        dv_int <= 1;
        dout_int <= {mcount_out, {pkt_start_word, 1'b0}, src_id_out};

        // State transition logic
        // If zero data words per packet (pathological, I know...)
        if(nwords_per_pkt == 0)
          state <= CRC;
        else
          // Move on to DATA state
          state <= DATA;
      end
      DATA: begin
        // Data state runs two out of every 3 cycles
        if(oe) begin

          // Drive outputs
          dv_int <= 1;
          dout_int <= databuf[rd_addr];
          rd_addr <= rd_addr + 1;

          // State transition logic
          // If last word of packet
          if(pkt_word_count == pkt_stop_word) begin
            pkt_word_count <= 0;
            state <= CRC;
          end else begin
            pkt_word_count <= pkt_word_count + 1;
          end
        end
      end
      CRC: begin
        // Drive outputs
        dout_int <= {64{1'b1}};
        dv_int <= 1;
        eof_int <= 1;

        // State transition logic
        // If last packet
        if(dst_int == 7) begin
          // No more packets, return to IDLE
          pkt_start_word <= 0;
          dst_int <= 0;
          state <= IDLE;
        end else begin
          // Setup for next packet
          pkt_start_word <= pkt_start_word + nwords_per_pkt;
          dst_int <= dst_int + 1;
          // Go to HEADER state
          state <= HEADER;
        end
      end
    endcase
  end // if reset, else transition
end

// CRC module
crc32x64 crc_gen (
  .clk(clk),
  .ce(1'b1),
  .valid_in(dv_int),
  .init_in(sof_int),
  .data_in(dout_int),
  .valid_out(dv_crc),
  .data_out(dout_crc),
  .crc(crc_crc)
);

// The eof and dst pipelines
always @(posedge clk) begin
  dst_pipeline[0] <= dst_int;
  eof_pipeline[0] <= eof_int;
  for(i=1; i<CRC_LATENCY; i=i+1) begin
    dst_pipeline[i] <= dst_pipeline[i-1];
    eof_pipeline[i] <= eof_pipeline[i-1];
  end
end

// The CRC mux
always @(posedge clk) begin
  dv <= dv_crc;
  dst_delay <= dst_pipeline[CRC_LATENCY-1];
  dst <= dst_delay;
  eof <= eof_pipeline[CRC_LATENCY-1];
  // Invert and byte swap so that the CRC will be compatible with zlib's crc32
  // function, allowing for easy verification on computers.
  crc_crc1 <= ~{crc_crc[7:0], crc_crc[15:8], crc_crc[23:16], crc_crc[31:24]};
  if(eof_pipeline[CRC_LATENCY-1])
    dout <= {crc_crc1, 32'b0};
  else
    dout <= dout_crc;
end

endmodule