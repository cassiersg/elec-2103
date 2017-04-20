module rpi_mmu (
	// RPi SPI interface
	input logic rpi_we,
	input logic [23:0] rpi_addr,
	input logic [31:0] rpi_wd,
	output logic [31:0] rpi_rd,
	input logic rpi_re,
	// message memory
	output logic [15:0] message_addr,
	output logic message_we,
	output logic [31:0] message_wd,
	input logic [31:0] message_rd,
	output logic message_re,
	// tile idx memory
	output logic [15:0] tile_idx_addr,
	output logic tile_idx_we,
	output logic [31:0] tile_idx_wd,
	input logic [31:0] tile_idx_rd,
	output logic tile_idx_re,
	
	input logic [31:0] display_ctrl_rd,
	output logic [31:0] display_ctrl_wd,
	output logic display_ctrl_we
);

logic [7:0] chip;
assign chip  = rpi_addr[23:16];

assign message_addr = rpi_addr[15:0];
assign tile_idx_addr = rpi_addr[15:0];

always_comb
case (chip)
	8'h00: rpi_rd = message_rd;
	8'h01: rpi_rd = tile_idx_rd;
	8'h02: rpi_rd = display_ctrl_rd;
	default: rpi_rd = 32'b0;
endcase

assign message_wd = rpi_wd;
assign tile_idx_wd = rpi_wd;
assign display_ctrl_wd = rpi_wd;

assign message_we = (chip == 8'h00) & rpi_we;
assign tile_idx_we = (chip == 8'h01) & rpi_we;
assign display_ctrl_we = (chip == 8'h02) & rpi_we;

assign message_re = (chip == 8'h00) & rpi_re;
assign tile_idx_re = (chip == 8'h01) & rpi_re;

endmodule