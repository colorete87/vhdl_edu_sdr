


.PHONY: all
all: design_symb_sync_filters

.PHONY: design_symb_sync_filters
design_symb_sync_filters:
	@echo "Designing Symbol Synchronization filters!"
	@cd coeffs_generators && octave design_symb_sync_filters.m
	@echo "Done!"

.PHONY: generate_vhdl_for_pulse_filter
generate_vhdl_for_pulse_filter:
	@echo "Generating VHDL code for Pulse-Shaping filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_for_pulse_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_pulse_shaping_fir.vhd ../src/pulse_shaping/
	@echo "Done!"

.PHONY: generate_vhdl_channel_filter
generate_vhdl_channel_filter:
	@echo "Generating VHDL code for Channel filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_channel_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_channel_fir.vhd ../src/channel/
	@echo "Done!"
