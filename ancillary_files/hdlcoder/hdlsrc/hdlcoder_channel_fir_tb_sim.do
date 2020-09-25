onbreak resume
onerror resume
vsim -novopt work.hdlcoder_channel_fir_tb
add wave sim:/hdlcoder_channel_fir_tb/u_hdlcoder_channel_fir/clk
add wave sim:/hdlcoder_channel_fir_tb/u_hdlcoder_channel_fir/clk_enable
add wave sim:/hdlcoder_channel_fir_tb/u_hdlcoder_channel_fir/reset
add wave sim:/hdlcoder_channel_fir_tb/u_hdlcoder_channel_fir/filter_in
add wave sim:/hdlcoder_channel_fir_tb/u_hdlcoder_channel_fir/filter_out
add wave sim:/hdlcoder_channel_fir_tb/filter_out_ref
run -all
