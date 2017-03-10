module display_mmu #(parameter ADDR_WIDTH)(
    input logic [31:0] tile_idx_0_rd, tile_idx_1_rd,
    output logic [31:0] tile_idx_display_rd, tile_idx_rpi_rd,
    input logic [ADDR_WIDTH-1:0] tile_idx_display_adddr, tile_idx_rpi_addr,
    output logic [ADDR_WIDTH-1:0] tile_idx_0_addr, tile_idx_1_addr,
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
    end
    else
    begin
        tile_idx_display_rd = tile_idx_0_rd;
        tile_idx_rpi_rd = tile_idx_1_rd;
        tile_idx_0_addr = tile_idx_display_addr;
        tile_idx_1_addr = tile_idx_rpi_addr;
    end
end

endmodule
