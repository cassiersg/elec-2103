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
    input logic [10:0] i_next_x,
    input logic [9:0] i_next_y
	 // display RAM
//	 input logic [31:0] i_disp_RAM_readdata,
	// output logic [31:0] o_disp_RAM_address
);

logic [10:0] x;
logic [9:0] y;
assign x = i_next_x;
assign y = i_next_y;
	always_ff @(posedge iCLK_33)
	begin
		if (i_next_active && x >= 0 && x < 800 && y >= 0 && y < 480) o_pixel_data <= 32'h000000FF;
	//	else if (i_next_x == 1 || i_next_x == 798 || i_next_y == 1 || i_next_y == 478) o_pixel_data <= 32'h000000FF;
	//	else if (i_next_x == 0 || i_next_x == 799 || i_next_y == 0 || i_next_y == 479) o_pixel_data <= 32'h00FF0000;
	//	else if (i_next_x > 2 && i_next_x < 797 && i_next_y > 2 && i_next_y < 477) o_pixel_data <= 23'h00000000;
		else o_pixel_data <= 32'h00FF0000;
	end

endmodule 
