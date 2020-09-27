onbreak resume
onerror resume
vsim -novopt work.hdlcoder_pre_filter_tb
add wave sim:/hdlcoder_pre_filter_tb/u_hdlcoder_pre_filter/clk
add wave sim:/hdlcoder_pre_filter_tb/u_hdlcoder_pre_filter/clk_enable
add wave sim:/hdlcoder_pre_filter_tb/u_hdlcoder_pre_filter/reset
add wave sim:/hdlcoder_pre_filter_tb/u_hdlcoder_pre_filter/filter_in
add wave sim:/hdlcoder_pre_filter_tb/u_hdlcoder_pre_filter/filter_out
add wave sim:/hdlcoder_pre_filter_tb/filter_out_ref
run -all
