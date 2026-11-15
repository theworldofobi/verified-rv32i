# Makefile usage
# make                 run all directed tests on the default DUT 
# make DUT=single      single-cycle core
# make DUT=pipeline    5-stage pipeline (tba)
# make test T=alu      run one directed test
# make lint            Verilator lint of the RTL

RISCV_PREFIX ?= riscv64-unknown-elf-
CC      := $(RISCV_PREFIX)gcc
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump
ARCH    := -march=rv32i -mabi=ilp32
CFLAGS  := $(ARCH) -nostdlib -nostartfiles -mno-relax -T link.ld -Iasm -Wl,--no-warn-rwx-segments

DUT     ?= single
RTL_DIR := ../rtl
TB_DIR  := tb
BUILD   := build

RTL := $(RTL_DIR)/rv32i_pkg.sv $(RTL_DIR)/alu.sv $(RTL_DIR)/regfile.sv \
       $(RTL_DIR)/imm_gen.sv $(RTL_DIR)/decoder.sv $(RTL_DIR)/branch_unit.sv \
       $(RTL_DIR)/lsu.sv $(RTL_DIR)/rv32i_single.sv
RTL += $(wildcard $(RTL_DIR)/rv32i_pipeline.sv $(RTL_DIR)/hazard_unit.sv)
TB  := $(TB_DIR)/rv32i_iss_pkg.sv $(TB_DIR)/tb_mem.sv $(TB_DIR)/tb_top.sv

VFLAGS := --binary --timing --assert -j 0 -Wno-fatal \
          -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-DECLFILENAME -Wno-MULTIDRIVEN \
          --top-module tb_top
ifeq ($(DUT),pipeline)
VFLAGS += -DDUT_PIPELINE
endif

SIM := $(BUILD)/$(DUT)/Vtb_top

ASM_TESTS  := alu upper branch branch_far mem $(notdir $(basename $(wildcard asm/hazard*.S)))
TRAP_TESTS := illegal illegal_shift

.PHONY: all test lint clean
.SECONDARY:

all: $(SIM) $(ASM_TESTS:%=$(BUILD)/prog/%.hex) $(TRAP_TESTS:%=$(BUILD)/prog/%.hex)
	@# pass/fail comes from the simulator's exit status ($$fatal on any error),
	@# not from grep: grep "succeeds" on a FAIL line too.
	@fail=0; npass=0; ntot=0; \
	run() { ntot=$$((ntot+1)); \
	  $(SIM) "$$@" > $(BUILD)/run.log 2>&1; rc=$$?; \
	  grep -E 'PASS|FAIL|MISMATCH|dut:|ref:|self-check|TIMEOUT|unexpected|status' $(BUILD)/run.log; \
	  if [ $$rc -eq 0 ]; then npass=$$((npass+1)); else fail=1; fi; }; \
	for t in $(ASM_TESTS);  do run +HEX=$(BUILD)/prog/$$t.hex +SELFCHECK;   done; \
	for t in $(TRAP_TESTS); do run +HEX=$(BUILD)/prog/$$t.hex +EXPECT_TRAP; done; \
	echo "== $$npass/$$ntot tests passed"; \
	exit $$fail

test: $(SIM) $(BUILD)/prog/$(T).hex
	$(SIM) +HEX=$(BUILD)/prog/$(T).hex +SELFCHECK $(ARGS)

$(SIM): $(RTL) $(TB)
	verilator $(VFLAGS) -Mdir $(BUILD)/$(DUT) $(RTL) $(TB) -o Vtb_top >$(BUILD)/$(DUT).log 2>&1 \
	  || (cat $(BUILD)/$(DUT).log; exit 1)

LINT := verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM

lint:
	$(LINT) --top-module rv32i_single $(RTL)
	@if [ -f $(RTL_DIR)/rv32i_pipeline.sv ]; then $(LINT) --top-module rv32i_pipeline $(RTL); fi

# programs
$(BUILD)/prog/%.elf: asm/%.S asm/test_macros.h link.ld
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/prog/%.hex: $(BUILD)/prog/%.elf
	$(OBJCOPY) -O binary $< $(@:.hex=.bin)
	python3 scripts/bin2hex.py $(@:.hex=.bin) $@
	$(OBJDUMP) -d $< > $(@:.hex=.dis)

$(shell mkdir -p $(BUILD))

clean:
	rm -rf $(BUILD)
