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
//  Note that CRC is in the upper 32 bits of the 64-bit word and zeros are in
//  the lower 32 bits.
//
// * Header format (for NWORDS=2048)
// 
//     {scount[47:0}, {word[10:0], 1'b0}, src_id[3:0]}
//

(*
  fsm_extract = "no",
  equivalent_register_removal = "no"
*)

module s6_packetizer
#(
  parameter integer NWORDS = 2048
)
(
  input clk,
  // verilator lint_off UNUSED
  input ce,
  // verilator lint_on UNUSED
  input sync,
  input [63:0] din,
  input [NWORDS_BITS-1:0] start_word,
  input [NWORDS_BITS-1:0] nwords_per_pkt,
  input [3:0] src_id,
  output [63:0] dout,
  output dv,
  output [3:0] dst,
  output eof
);

// Output registers
reg [63:0] dout_reg; assign dout = dout_reg;
reg        dv_reg;   assign dv   = dv_reg;
reg  [3:0] dst_reg;  assign dst  = dst_reg;
reg        eof_reg;  assign eof  = eof_reg;

// Xilinx xst doesn't like using system function calls like $clog to assign to
// localparams, so we define this constant function "clog" to replace the
// system function $clog.
function integer clog2(input integer n);
  begin
    n = n - 1;
    for(clog2=0; n>0; clog2=clog2+1)
      n = n >> 1;
  end
endfunction

localparam NWORDS_BITS = clog2(NWORDS);

// The safe minimum for DATABUF_DEPTH is at most 2/3 NWORDS, but since that is
// more than half we are setting it equal to NWORDS (for now).
localparam DATABUF_DEPTH = NWORDS;
localparam DATABUF_DEPTH_BITS = clog2(NWORDS);

localparam CRC_LATENCY = 7;

(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] start_word_reg = 0;
(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] nwords_per_pkt_reg = 0;
(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] stop_word = 0;
(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] word_count = 0;
(* equivalent_register_removal = "no" *)
reg [64-(NWORDS_BITS+1)-4-1:0] mcount = 0;
(* equivalent_register_removal = "no" *)
reg [64-(NWORDS_BITS+1)-4-1:0] mcount_out = 0;
(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] pkt_start_addr = 0;
(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] pkt_start_word = 0;
(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] pkt_stop_word = 0;
reg [3:0] src_id_out = 0;

reg [63:0] din_reg = 0;

(* equivalent_register_removal = "no" *)
reg [63:0] dout_int = 0;
(* equivalent_register_removal = "no" *)
reg        dv_int = 0;
(* equivalent_register_removal = "no" *)
reg [ 3:0] dst_int = 0, dst_pipeline[CRC_LATENCY-1:0], dst_delay = 0;
(* equivalent_register_removal = "no" *)
reg        eof_int = 0, eof_pipeline[CRC_LATENCY-1:0];
(* equivalent_register_removal = "no" *)
reg        sof_int = 0;

wire [63:0] dout_crc;
wire dv_crc;
wire [31:0] crc_crc;
reg  [31:0] crc_crc1 = 0;

// Data buffer is 64 bits wide
reg [63:0] databuf[DATABUF_DEPTH-1:0];
reg [63:0] databuf_out = 0;

(* equivalent_register_removal = "no" *)
reg databuf_we = 1'b0;
(* equivalent_register_removal = "no" *)
reg [DATABUF_DEPTH_BITS-1:0] wr_addr = 0;
(* equivalent_register_removal = "no" *)
reg [DATABUF_DEPTH_BITS-1:0] rd_addr = 0;

// Output state machine
localparam IDLE   = 2'b00;
localparam HEADER = 2'b01;
localparam DATA   = 2'b10;
localparam CRC    = 2'b11;
(*
  fsm_extract = "no",
  equivalent_register_removal = "no"
*)
reg [1:0] state = IDLE;

(* equivalent_register_removal = "no" *)
reg [NWORDS_BITS-1:0] pkt_word_count = 0;
(* equivalent_register_removal = "no" *)
reg [2:0] oe_shift_reg = 0;
(* equivalent_register_removal = "no" *)
reg start = 0;
(* equivalent_register_removal = "no" *)
reg nodata_packets = 0;
(* equivalent_register_removal = "no" *)
reg last_packet = 0;

// General purpose loop variable
integer i;

// Initialize output registers and memories simulation (and FPGA?)
initial begin
  for(i=0; i<DATABUF_DEPTH; i=i+1)
    databuf[i] = 0;
  for(i=0; i<CRC_LATENCY; i=i+1) begin
    dst_pipeline[i] = 0;
    eof_pipeline[i] = 0;
  end
  dout_reg = 64'b0;
  dv_reg = 1'b0;
  dst_reg = 4'h0;
  eof_reg = 1'b0;
end

// Word_count and mcount
always @(posedge clk) begin
  if(sync == 1'b1) begin
    // Reset
    word_count <= 0;
    mcount <= 0;
  // verilator lint_off WIDTH
  end else if(word_count == NWORDS-1) begin
  // verilator lint_on WIDTH
    // Roll over word_count, increment mcount
    word_count <= {NWORDS_BITS{1'b0}};
    mcount <= mcount + 1;
  end else begin
    // increment word_count
    word_count <= word_count + 1;
  end
end

// Pipelined calculations of stop_word and pkt_stop_word.
// These are expected to change very infrequently.
always @(posedge clk) begin
  start_word_reg <= start_word;
  nwords_per_pkt_reg <= nwords_per_pkt;
  stop_word <= start_word_reg + (nwords_per_pkt_reg<<3) - 1;
  pkt_stop_word <= nwords_per_pkt_reg - 1;
end

// Data buffer write enable logic
always @(posedge clk) begin
  din_reg <= din; // Delay din
  if(sync == 1) begin
    wr_addr <= 0;
    databuf_we <= 0;
  end else begin

    // Databuf write
    if(databuf_we == 1)
      databuf[wr_addr] <= din_reg;

    // Databuf read
    databuf_out <= databuf[rd_addr];

    // Write control logic
    if(word_count == start_word_reg) begin
      databuf_we <= 1;
    end

    // Write address generation
    if(databuf_we) begin
      if(wr_addr == stop_word) begin
        wr_addr <= 0;
        databuf_we <= 0;
      end else
        wr_addr <= wr_addr + 1;
    end

  end
end

// Output FSM state transition logic
always @(posedge clk) begin
  // DV and DST are 0 unless explicitly set to 1
  dv_int <= 0;
  sof_int <= 0;
  eof_int <= 0;

  if(sync == 1) begin
    // Reset
    state <= IDLE;
    pkt_start_word <= 0;
    pkt_word_count <= 0;
    oe_shift_reg <= 0;
    start <= 0;
    nodata_packets <= 0;
    last_packet <= 0;
  end else begin

    if(word_count == start_word_reg) begin
      // Register mcount and src_id so that they will not change on us
      // during this output cycle.
      mcount_out <= mcount;
      src_id_out <= src_id;
      pkt_start_word <= start_word_reg;
      // Start reading location 0; data valid after two cycles.
      rd_addr <= 0;
      pkt_start_addr <= nwords_per_pkt_reg;
      // Set "start" flag
      start <= 1;
    end else
      start <= 0;


    // Send "no data" packets?
    nodata_packets <= (nwords_per_pkt_reg == 0);

    // Detect last packet
    last_packet <= (dst_int == 7);

    // State transition
    case(state)
      IDLE: begin
        // Move to header state once we get the start signal
        if(start) begin
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
        if(nodata_packets)
          state <= CRC;
        else begin
          // Read next location (keep feeding the pipeline)
          rd_addr <= rd_addr + 1;
          // Prime the output enable shift register
          oe_shift_reg <= 3'b110;
          // Move on to DATA state
          state <= DATA;
        end
      end
      DATA: begin
        // oe_shift_reg will be 3'b110 for the DATA first cycle.
        // Rotate output enable bits left
        oe_shift_reg <= {oe_shift_reg[1:0], oe_shift_reg[2]};

        if(oe_shift_reg[2]) begin
          // Drive outputs
          dv_int <= 1;
          dout_int <= databuf_out;

          // If last word of packet
          if(pkt_word_count == pkt_stop_word) begin
            oe_shift_reg <= 0;
            pkt_word_count <= 0;
            // Advance to CRC state
            state <= CRC;
          end else begin
            pkt_word_count <= pkt_word_count + 1;
          end
        end

        // We have already (pre-)fetched two words, so we don't need to
        // advance if oe_shift_reg[1] is 0.
        if(oe_shift_reg[1])
          rd_addr <= rd_addr + 1;

      end
      CRC: begin
        // Drive outputs
        dout_int <= {64{1'b1}};
        dv_int <= 1;
        eof_int <= 1;

        // State transition logic
        // If last packet
        if(last_packet) begin
          // No more packets, return to IDLE
          pkt_start_word <= 0;
          dst_int <= 0;
          state <= IDLE;
        end else begin
          // Start fetching data for start of next packet (takes two cycles)
          rd_addr <= pkt_start_addr;
          // Setup for next packet
          pkt_start_addr <= pkt_start_addr + nwords_per_pkt_reg;
          pkt_start_word <= pkt_start_word + nwords_per_pkt_reg;
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
  .crc(crc_crc),
  // verilator lint_off PINCONNECTEMPTY
  .init_out(/*NC*/)
  // verilator lint_on PINCONNECTEMPTY
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
  dv_reg <= dv_crc;
  dst_delay <= dst_pipeline[CRC_LATENCY-1];
  dst_reg <= dst_delay;
  eof_reg <= eof_pipeline[CRC_LATENCY-1];
  // Invert and byte swap so that the CRC will be compatible with zlib's crc32
  // function, allowing for easy verification on computers.
  crc_crc1 <= ~{crc_crc[7:0], crc_crc[15:8], crc_crc[23:16], crc_crc[31:24]};
  if(eof_pipeline[CRC_LATENCY-1])
    dout_reg <= {crc_crc1, 32'b0};
  else
    dout_reg <= dout_crc;
end

endmodule
