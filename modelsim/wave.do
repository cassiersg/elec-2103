onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /display_tb/clk
add wave -noupdate /display_tb/rst_n
add wave -noupdate /display_tb/next_display_active
add wave -noupdate /display_tb/new_frame
add wave -noupdate /display_tb/end_frame
add wave -noupdate /display_tb/hsync
add wave -noupdate /display_tb/vsync
add wave -noupdate -radix decimal /display_tb/pix_counter
add wave -noupdate /display_tb/color
add wave -noupdate /display_tb/ok
add wave -noupdate /display_tb/dut2/RAM_readdata
add wave -noupdate /display_tb/dut2/color
add wave -noupdate /display_tb/dut2/RAM_address
add wave -noupdate /display_tb/dut2/buffer_lsb
add wave -noupdate /display_tb/dut2/buffer_msb
add wave -noupdate /display_tb/dut2/color_next
add wave -noupdate /display_tb/dut2/length
add wave -noupdate /display_tb/dut2/length_next
add wave -noupdate /display_tb/dut2/length_counter
add wave -noupdate /display_tb/dut2/offset
add wave -noupdate /display_tb/dut2/offset_next
add wave -noupdate /display_tb/dut2/offset_tot
add wave -noupdate /display_tb/dut2/len_code_color
add wave -noupdate /display_tb/dut2/len_code_length
add wave -noupdate /display_tb/dut2/code_color
add wave -noupdate /display_tb/dut2/code_length
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {49170900 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {49170500 ps} {49176700 ps}
