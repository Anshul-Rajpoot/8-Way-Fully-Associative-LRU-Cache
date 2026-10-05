SIM ?= iverilog
VVP ?= vvp
BUILD_DIR ?= build
SIM_BINARY := $(BUILD_DIR)/cache_lru_tb
VCD_FILE := $(BUILD_DIR)/cache_lru.vcd

RTL := rtl/cache_lru_fully_assoc.v
TB := tb/tb_cache_lru_fully_assoc.v

.PHONY: all compile run wave clean help

all: run

help:
	@echo "Available targets:"
	@echo "  make         Compile and run self-checking testbench"
	@echo "  make compile Compile only"
	@echo "  make run     Compile and run"
	@echo "  make wave    Compile, run, and generate VCD waveform"
	@echo "  make clean   Remove generated build files"

compile:
	mkdir -p $(BUILD_DIR)
	$(SIM) -g2012 -Wall -o $(SIM_BINARY) $(RTL) $(TB)

run: compile
	$(VVP) $(SIM_BINARY)

wave: compile
	$(VVP) $(SIM_BINARY) +WAVE
	@echo "Waveform: $(VCD_FILE)"

clean:
	rm -rf $(BUILD_DIR)
