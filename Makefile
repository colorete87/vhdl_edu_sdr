
BASE_REL_DIR = ../../
VER_DIR      = ./verification/

# Waves output format (vcd,fst)
WOF = fst
WAVES_NAME = waves.$(WOF)
WLIB_NAME  = work-obj93.cf

RUN_FLAGS = --disp-time
RUN_FLAGS =

DATA_FILES =

SRC_DIRS  = ./src
SRC_DIRS += ./src/lib
SRC_DIRS += ./src/lib/uart
SRC_DIRS += ./src/lib/fifo
SRC_DIRS += ./src/top
SRC_DIRS += ./src/modulator
SRC_DIRS += ./src/modulator/pulse_shaping
SRC_DIRS += ./src/channel/
SRC_DIRS += ./src/channel/filter
SRC_DIRS += ./src/channel/prng
SRC_DIRS += ./src/demodulator
SRC_DIRS += ./src/demodulator/matched_filter
SRC_DIRS += ./src/demodulator/pll
SRC_DIRS += ./src/demodulator/pre_filter
SRC_DIRS += ./src/demodulator/bandpass_filter
SRC_DIRS += ./src_test
SRC_FILES = $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.vhd))

# GHDL_OPTIONS = --std=02 --ieee=synopsys --work=$(WLIB_NAME)
GHDL_OPTIONS = --std=02 --ieee=synopsys
GTKWAVE_OPTIONS = --optimize

SRC_REL_FILES = $(addprefix $(BASE_REL_DIR),$(SRC_FILES))

TBS       = $(notdir $(wildcard $(VER_DIR)*))
TBS_WAVES = $(addsuffix /$(WAVES_NAME),$(addprefix $(VER_DIR),$(TBS)))
TBS_EXE   = $(addprefix $(VER_DIR),$(join $(addsuffix /,$(TBS)),$(TBS)))
TBS_WLIBS = $(addsuffix /$(WLIB_NAME),$(addprefix $(VER_DIR),$(TBS)))

.PHONY: all
all:
	@echo "Must provide one of the following TestBenches:"
	@$(foreach tb,$(TBS),echo "  "$(tb);)
	@echo


$(TBS_WLIBS):
	@echo "Generating WORK Library for $@"
	@cd $(dir $@) && \
	 	ghdl -i $(GHDL_OPTIONS) *.vhd $(SRC_REL_FILES)


.SECONDEXPANSION:
$(TBS_EXE) : % : %.vhd $$(dir $$@)$(WLIB_NAME) $(SRC_FILES)
	@cd $(dir $@) && \
		ghdl -m $(GHDL_OPTIONS) $(notdir $@)


# .SECONDEXPANSION:
# $(TBS_WAVES): $(VER_DIR)%/waves.$(WOF) : $$(subst waves.$$(WOF),,$$@)% $(DATA_FILES)
# 	$< --$(WOF)=$@ $(RUN_FLAGS)
# 	@echo "File $< Updated! (Reload Waveform)"
.SECONDEXPANSION:
$(TBS_WAVES): $(VER_DIR)%/waves.$(WOF) : $$(subst waves.$$(WOF),,$$@)% $(DATA_FILES)
	@cd $(dir $@) && \
		ghdl -r $(notdir $<) --$(WOF)=waves.$(WOF) $(RUN_FLAGS)
	@echo "File $< Updated! (Reload Waveform)"


$(TBS): % : $(VER_DIR)%/waves.$(WOF)
	@echo "Done $@!"


$(TBS:%=gtkwave_%): gtkwave_% : $(VER_DIR)%/waves.$(WOF)
	gtkwave $< $(GTKWAVE_OPTIONS) &


.PHONY: clean
clean:
	@clear
	-$(foreach tb,$(VER)$(TBS),rm -f $(VER_DIR)$(tb)/*.o;)
	-rm -f $(TBS_EXE)
	-rm -f $(TBS_WAVES)
	-rm -f $(TBS_WLIBS)







# Other "USEFULL" things
.PHONY: list_targets
list_targets:
	@echo "TESTS:"
	@$(foreach var,$(TBS),echo "  "$(var);)
	@echo "EXE"
	@$(foreach var,$(TBS_EXE),echo "  "$(var);)
	@echo "WAVES"
	@$(foreach var,$(TBS_WAVES),echo "  "$(var);)
	@echo "WLIBS"
	@$(foreach var,$(TBS_WLIBS),echo "  "$(var);)
	@echo


.PHONY: list_src_files
list_src_files:
	@echo "SRC FILES"
	@$(foreach var,$(SRC_FILES),echo "  "$(var);)
	@echo


.PHONY: list_src_dir
list_src_dir:
	@echo "SRC DIRS"
	@$(foreach var,$(SRC_DIRS),echo "  "$(var);)
	@echo


.PHONY: list_tests
list_tests:
	@echo "SRC FILES"
	@$(foreach var,$(TBS),echo "  "$(var);)
	@echo

