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
    input logic [10:0] i_next2_x,
    input logic [9:0] i_next2_y,
	 // display RAM
	 input logic [7:0] i_tiles_readdata, i_tiles_idx_readdata,
	input logic [31:0] i_display_ctrl_readdata, i_colormap_readdata,
	 output logic [31:0] o_tiles_addr, o_tiles_idx_addr, o_display_ctrl_addr, o_colormap_addr
);

parameter TILES_PER_LINE = 100;

// skip 3 LSB of x and y to divide by 8
assign o_tiles_idx_addr = i_next2_x[10:3] + i_next2_y[9:3] * TILES_PER_LINE;

logic [5:0] tile_image_offset;
always_ff @(posedge iCLK_33)
	tile_image_offset = {i_next2_y[2:0], i_next2_x[2:0]};

assign o_tiles_addr = {i_tiles_idx_readdata, tile_image_offset};
assign o_colormap_addr = i_tiles_readdata;

always_ff @(posedge iCLK_33)
	o_pixel_data <= i_colormap_readdata;

endmodule
