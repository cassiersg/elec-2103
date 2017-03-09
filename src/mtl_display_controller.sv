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
	 input logic [31:0] i_tiles_readdata,
	input logic [31:0] i_display_ctrl_readdata, i_colormap_readdata, i_tiles_idx_readdata,
	 output logic [31:0] o_tiles_addr, o_tiles_idx_addr, o_display_ctrl_addr, o_colormap_addr
);

parameter TILES_PER_LINE = 100;

logic [7:0] tile_idx;
// skip 3 LSB of x and y to divide by 8
char_memory #(30) char_mem_tile_idx(
	.char_readdata(tile_idx),
	.mem_readdata(i_tiles_idx_readdata),
	.mem_address(o_tiles_idx_addr),
	.char_address(i_next2_x[10:3] + i_next2_y[9:3] * TILES_PER_LINE)
);

logic [5:0] tile_image_offset;
always_ff @(posedge iCLK_33)
	tile_image_offset = {i_next2_y[2:0], i_next2_x[2:0]};

char_memory #(30) char_mem_tile_image (
	.char_readdata(o_colormap_addr),
	.mem_readdata(i_tiles_readdata),
	.mem_address(o_tiles_addr),
	.char_address({tile_idx, tile_image_offset})
);

always_ff @(posedge iCLK_33)
	o_pixel_data <= i_colormap_readdata;

endmodule

module char_memory #(parameter MEM_ADDR_WIDTH=30)(
	output logic [7:0] char_readdata,
	input logic [31:0] mem_readdata,
	output logic [MEM_ADDR_WIDTH-1:0] mem_address,
	input logic [MEM_ADDR_WIDTH+1:0] char_address
);

assign mem_address = char_address[MEM_ADDR_WIDTH+1:2];
always_comb
case (char_address[1:0])
	2'h0: char_readdata = mem_readdata[7:0];
	2'h1: char_readdata = mem_readdata[15:8];
	2'h2: char_readdata = mem_readdata[23:16];
	2'h3: char_readdata = mem_readdata[31:24];
endcase

endmodule
