
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


.SECONDEXPANSION:
$(TBS_WAVES): $(VER_DIR)%/waves.$(WOF) : $$(subst waves.$$(WOF),,$$@)% $(DATA_FILES)
	$< --$(WOF)=$@ $(RUN_FLAGS)
	@echo "File $< Updated! (Reload Waveform)"


$(TBS): % : $(VER_DIR)%/waves.$(WOF)
	@echo "Done $@!"


$(TBS:%=gtkwave_%): gtkwave_% : $(VER_DIR)%/waves.$(WOF)
	gtkwave $< $(GTKWAVE_OPTIONS) &


.PHONY: clean
clean:
	@clear
	-$(foreach tb,$(VER)$(TBS),rm $(VER_DIR)$(tb)/*.o;)
	-rm $(TBS_EXE)
	-rm $(TBS_WAVES)
	-rm $(TBS_WLIBS)







# Other "USEFULL" things
.PHONY: list_targets
list_targets:
	@echo "TESTS:"
	@$(foreach tb,$(TBS),echo "  "$(tb);)
	@echo "EXE"
	@$(foreach tb,$(TBS_EXE),echo "  "$(tb);)
	@echo "WAVES"
	@$(foreach tb,$(TBS_WAVES),echo "  "$(tb);)
	@echo "WLIBS"
	@$(foreach tb,$(TBS_WLIBS),echo "  "$(tb);)
	@echo


.PHONY: list_src_files
list_src_files:
	@echo "SRC FILES"
	@$(foreach tb,$(SRC_FILES),echo "  "$(tb);)
	@echo


.PHONY: list_tests
list_tests:
	@echo "SRC FILES"
	@$(foreach tb,$(TBS),echo "  "$(tb);)
	@echo

