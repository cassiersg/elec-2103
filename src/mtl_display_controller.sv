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
	 input logic [31:0] i_tiles_readdata, i_tiles_idx_readdata, i_display_ctrl_readdata,
	 output logic [31:0] o_tiles_addr, o_tiles_idx_addr, o_display_ctrl_addr
);

parameter TILES_PER_LINE = 100;

logic [31:0] tile_nb;
assign tile_nb = i_next2_x[10:3] + i_next2_y[9:3] * TILES_PER_LINE;
assign o_tiles_idx_addr = tile_nb[31:2];
logic [7:0] tile_idx_next, tile_idx;
always_comb
case (tile_nb[1:0])
	2'h0: tile_idx_next = i_tiles_idx_readdata[7:0];
	2'h1: tile_idx_next = i_tiles_idx_readdata[15:8];
	2'h2: tile_idx_next = i_tiles_idx_readdata[23:16];
	2'h3: tile_idx_next = i_tiles_idx_readdata[31:24];
endcase
always_ff @(posedge iCLK_33)
	tile_idx = tile_idx_next;
assign o_tiles_addr = tile_idx * 64 + i_next2_y[2:0] * 8 + i_next2_x[2:0];

always_ff @(posedge iCLK_33)
begin
	o_pixel_data <= i_tiles_readdata;
end

endmodule 
