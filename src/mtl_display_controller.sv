module mtl_display_controller (
    // global system
	input 			iCLK_50,			// System Clock (50MHz)
	input    		iCLK_33,	// MTL Clock (33 MHz, 0°)
    input 			iRST,				// System sync reset
	// mtl_display
	input  iNew_Frame, // Control signal being a pulse when a new frame of the LCD begins
	input  iEnd_Frame,		// Control signal being a pulse when a frame of the LCD ends
	input  i_next_active,			// SDRAM read control signal
    output logic [31:0] o_pixel_data,

    input logic [10:0] i_current_x,
    input logic [9:0] i_current_y
);

	 assign o_pixel_data = 32'h00123456;

endmodule 
