module display_mmu #(parameter ADDR_WIDTH)(
    input logic [31:0] tile_idx_0_rd, tile_idx_1_rd,
    output logic [31:0] tile_idx_display_rd, tile_idx_rpi_rd,
    input logic [ADDR_WIDTH-1:0] tile_idx_display_addr, tile_idx_rpi_addr,
    output logic [ADDR_WIDTH-1:0] tile_idx_0_addr, tile_idx_1_addr,
	 output logic tile_idx_0_we, tile_idx_1_we,
	 input logic tile_idx_rpi_we,
	 output logic [31:0] tile_idx_0_wd, tile_idx_1_wd,
	 input logic [31:0] tile_idx_rpi_wd,
    input logic tile_idx_select
);


always_comb
begin
    if (tile_idx_select)
    begin
        tile_idx_display_rd = tile_idx_1_rd;
        tile_idx_rpi_rd = tile_idx_0_rd;
        tile_idx_1_addr = tile_idx_display_addr;
        tile_idx_0_addr = tile_idx_rpi_addr;
		  tile_idx_1_we = 1'b0;
		  tile_idx_0_we = tile_idx_rpi_we;
    end
    else
    begin
        tile_idx_display_rd = tile_idx_0_rd;
        tile_idx_rpi_rd = tile_idx_1_rd;
        tile_idx_0_addr = tile_idx_display_addr;
        tile_idx_1_addr = tile_idx_rpi_addr;
		  tile_idx_0_we = 1'b0;
		  tile_idx_1_we = tile_idx_rpi_we;
    end
end

endmodule
