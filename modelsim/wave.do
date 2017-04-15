onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /display_tb/clk
add wave -noupdate /display_tb/rst_n
add wave -noupdate /display_tb/next_display_active
add wave -noupdate /display_tb/new_frame
add wave -noupdate /display_tb/end_frame
add wave -noupdate /display_tb/hsync
add wave -noupdate /display_tb/vsync
add wave -noupdate -radix decimal /display_tb/next2x
add wave -noupdate -radix decimal /display_tb/next2y
add wave -noupdate -radix decimal /display_tb/pix_counter
add wave -noupdate -radix unsigned /display_tb/dut/x_next
add wave -noupdate -radix unsigned /display_tb/dut/y_next
add wave -noupdate /display_tb/color
add wave -noupdate /display_tb/ok
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1499865000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 123
configure wave -valuecolwidth 146
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
WaveRestoreZoom {0 ps} {1575 us}
