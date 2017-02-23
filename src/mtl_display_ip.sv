module mtl_display_ip (
    // Clock and reset
    input logic clk,
    input logic reset,
    
    // Avalon MM interface 
	input avs_s0_write,
    input avs_s0_address,
	input [7:0] avs_s0_writedata,
    
    output next_slide_pulse
);

assign next_slide_pulse = avs_s0_write && avs_s0_address == 1'b0 && avs_s0_writedata[0] == 1'b1;
/*
touch_buffer tb (
    .clk(clk),
    .rst(reset),
    .trigger(avs_s0_write && (avs_s0_writedata[0] == 1'b1)),
    .pulse(next_slide_pulse)
);
*/

endmodule
