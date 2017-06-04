VERILOG=iverilog -gstrict-expr-width

s6_packetizer_tb: s6_packetizer_tb.v s6_packetizer.v crc32x64.v crclut.v
	$(VERILOG) -Wall $(VFLAGS) -o $@ $^

s6_packetizer: s6_packetizer.v crc32x64.v crclut.v
	$(VERILOG) -Wall $(VFLAGS) -o $@ $^

crc32x64_tb: crc32x64_tb.v crc32x64.v crclut.v
	$(VERILOG) -Wall $(VFLAGS) -o $@ $^

all: s6_packetizer_tb s6_packetizer crc32x64_tb

run: s6_packetizer_tb
	./$<

syntax:
	$(VERILOG) -Wall $(VFLAGS) -t null s6_packetizer.v s6_packetizer_tb.v crc32x64.v crclut.v

clean:
	rm -f s6_packetizer
	rm -f s6_packetizer_tb
	rm -f s6_packetizer_tb.vcd

.PHONY: all clean run syntax
