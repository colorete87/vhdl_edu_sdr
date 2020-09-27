

.PHONY: all
all: all_filters

.PHONY: all_filters
all_filters: \
 	design_symb_sync_filters \
	generate_vhdl_for_pulse_filter \
	generate_vhdl_for_channel_filter \
	generate_vhdl_for_matched_filter \
	generate_vhdl_for_pre_filter \
	generate_vhdl_for_bandpass_filter

.PHONY: design_symb_sync_filters
design_symb_sync_filters:
	@echo "Designing Symbol Synchronization filters!"
	@cd coeffs_generators && octave design_symb_sync_filters.m
	@echo "Done!"

.PHONY: generate_vhdl_for_pulse_filter
generate_vhdl_for_pulse_filter:
	@echo "Generating VHDL code for Pulse-Shaping filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_for_pulse_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_pulse_shaping_fir.vhd ../src/modulator/pulse_shaping/
	@echo "Done!"

.PHONY: generate_vhdl_for_channel_filter
generate_vhdl_for_channel_filter:
	@echo "Generating VHDL code for Channel filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_for_channel_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_channel_fir.vhd ../src/channel/filter/
	@echo "Done!"

.PHONY: generate_vhdl_for_matched_filter
generate_vhdl_for_matched_filter:
	@echo "Generating VHDL code for Matched filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_for_matched_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_matched_filter_fir.vhd ../src/demodulator/matched_filter/
	@echo "Done!"

.PHONY: generate_vhdl_for_pre_filter
generate_vhdl_for_pre_filter:
	@echo "Generating VHDL code for Matched filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_for_pre_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_pre_filter.vhd ../src/demodulator/pre_filter/
	@echo "Done!"

.PHONY: generate_vhdl_for_bandpass_filter
generate_vhdl_for_bandpass_filter:
	@echo "Generating VHDL code for Matched filter!"
	@cd hdlcoder && matlab -nodesktop -nosplash -r "run generate_vhdl_for_bandpass_filter.m; exit"
	@cp hdlcoder/hdlsrc/hdlcoder_bandpass_filter.vhd ../src/demodulator/bandpass_filter/
	@echo "Done!"
