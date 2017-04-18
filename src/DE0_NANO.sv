module DE0_NANO(
	input           CLOCK_50,
	output  [7:0]   LED,
    input   [1:0]   KEY,
	input   [3:0]   SW,

	//////////// SDRAM //////////
	output  [12:0]  DRAM_ADDR,
	output  [1:0]   DRAM_BA,
	output          DRAM_CAS_N,
	output          DRAM_CKE,
	output          DRAM_CLK,
	output          DRAM_CS_N,
	inout   [15:0]  DRAM_DQ,
	output  [1:0]   DRAM_DQM,
	output          DRAM_RAS_N,
	output          DRAM_WE_N,

	//////////// EPCS //////////
	output          EPCS_ASDO,
	input           EPCS_DATA0,
	output          EPCS_DCLK,
	output          EPCS_NCSO,

	//////////// Accelerometer and EEPROM //////////
	output          G_SENSOR_CS_N,
	input           G_SENSOR_INT,
	output          I2C_SCLK,
	inout           I2C_SDAT,

	//////////// ADC //////////
	output          ADC_CS_N,
	output          ADC_SADDR,
	output          ADC_SCLK,
	input           ADC_SDAT,

	//////////// 2x13 GPIO Header //////////
	inout   [12:0]  GPIO_2,
	input   [2:0]   GPIO_2_IN,

	//////////// GPIO_0, GPIO_0 connects to GPIO Default //////////
	inout   [33:0]  GPIO_0,
	input   [1:0]   GPIO_0_IN,

	//////////// GPIO_1, GPIO_1 connects to the MTL Screen //////////
	output          MTL_DCLK,
	output          MTL_HSD,
	output          MTL_VSD,
	output          MTL_TOUCH_I2C_SCL,
	inout           MTL_TOUCH_I2C_SDA,
	input           MTL_TOUCH_INT_n,
	output  [7:0]   MTL_R,
	output  [7:0]   MTL_G,
	output  [7:0]   MTL_B
);

// System clocks and resets 
logic ClOCK_33;
logic CLOCK_33d;
logic RST;
logic dly_rstn;
logic rd_rst;
logic dly_rst;

// Synchronous system reset from R-PI
assign RST = GPIO_0[1];

// Synchronization module (TODO: useful?)
reset_delay	reset_delay_inst (		
    .iRSTN  (~RST),
    .iCLK   (CLOCK_50),
	.oRSTN  (dly_rstn),
	.oRD_RST(rd_rst),
	.oRST   (dly_rst)
);

// MTL control
logic CLOCK_33;
logic [31:0] pixel_rgb;
logic next_display_active;
logic New_Frame;
logic End_Frame;
logic [10:0] next_x;
logic [9:0] next_y;
logic [31:0] tiles_addr, tiles_idx_0_addr, tiles_idx_1_addr, colormap_addr;
logic [31:0] tiles_readdata, tiles_idx_0_readdata, tiles_idx_1_readdata, colormap_readdata;
logic [31:0] display_control;

logic [31:0] tile_idx_display_rd;
logic [10:0] tile_idx_display_addr;

logic [15:0] tile_idx_rpi_rd;
logic [10:0] tile_idx_rpi_addr;

logic tile_idx_rpi_we, tile_idx_0_we, tile_idx_1_we;
logic [31:0] tile_idx_rpi_wd, tile_idx_0_wd, tile_idx_1_wd;

display_mmu #(11) display_mmu_inst (
	.tile_idx_0_rd(tiles_idx_0_readdata),
	.tile_idx_1_rd(tiles_idx_1_readdata),
	.tile_idx_display_rd(tile_idx_display_rd),
	.tile_idx_rpi_rd(tile_idx_rpi_rd),
	.tile_idx_display_addr(tile_idx_display_addr),
	.tile_idx_rpi_addr(tile_idx_rpi_addr),
	.tile_idx_0_addr(tiles_idx_0_addr),
	.tile_idx_1_addr(tiles_idx_1_addr),
	.tile_idx_0_we(tile_idx_0_we),
	.tile_idx_1_we(tile_idx_1_we),
	.tile_idx_0_wd(tile_idx_0_wd),
	.tile_idx_1_wd(tile_idx_1_wd),
	.tile_idx_rpi_we(tile_idx_rpi_we),
	.tile_idx_rpi_wd(tile_idx_rpi_wd),
	.tile_idx_select(display_control[0])
);


huffman_chunk_decoder dut2(
    .clk(CLOCK_33),
    .pixel_read_next(next_display_active),
    .pixel_reset(End_Frame | RST),
    .RAM_readdata(tiles_idx_display_rd),
    .color(pixel_rgb),
    .RAM_address(tiles_idx_display_addr)
);
//// MTL DISPLAY CONTROLLER
//mtl_display_controller mtl_display_controller_inst (
//    .display_clock(CLOCK_33),
//    .reset(RST),
//    .iNew_Frame(New_Frame),
//    .iEnd_Frame(End_Frame),
//	 .i_next_active(next_display_active),
//    .o_pixel_data(pixel_rgb),
//    .i_next2_x(next_x),
//    .i_next2_y(next_y),
//	 .i_tiles_readdata(tiles_readdata),
//	 .o_tiles_addr(tiles_addr),
//	 .i_tiles_idx_readdata(tile_idx_display_rd),
//	 .o_tiles_idx_addr(tile_idx_display_addr),
//	 .i_colormap_readdata(colormap_readdata),
//	 .o_colormap_addr(colormap_addr)
//);

// MTL DISPLAY
mtl_display mtl_display_inst (
    // Host Side
    .iCLK(CLOCK_33),    // Input LCD control clock
    .iRST_n(~RST),      // Input system reset
    // MMU
    .iREAD_DATA(pixel_rgb),	// Input data from SDRAM (RGB)
    .next_display_active(next_display_active),
    .oNew_Frame(New_Frame),
    .oEnd_Frame(End_Frame),
    // LCD Side
    .oLCD_R(MTL_R),	// Output LCD horizontal sync 
    .oLCD_G(MTL_G),	// Output LCD vertical sync
    .oLCD_B(MTL_B),	// Output LCD red color data 
    .oHD(MTL_HSD),	// Output LCD green color data 
    .oVD(MTL_VSD),	// Output LCD blue color data 
    .o_next2_x(next_x),
    .o_next2_y(next_y)
);

// RPi MMU
logic message_we, message_re;
logic [31:0] message_rd, message_wd;
logic [15:0] message_addr;
rpi_mmu rpi_mmu_inst(
	// RPi SPI interface
	.rpi_we(mem_pi_we),
	.rpi_addr(mem_pi_addr),
	.rpi_wd(mem_pi_writedata),
	.rpi_rd(mem_pi_readdata),
	.rpi_re(mem_pi_read),
	// message memory
	.message_addr(message_addr),
	.message_we(message_we),
	.message_wd(message_wd),
	.message_rd(message_rd),
	.message_re(message_re),
	// tile idx memory
	.tile_idx_addr(tile_idx_rpi_addr),
	.tile_idx_we(tile_idx_rpi_we),
	.tile_idx_wd(tile_idx_rpi_wd),
	.tile_idx_rd(tile_idx_rpi_rd)
	//.tile_idx_re()
);


// SPI instantiation
logic mem_pi_we, mem_pi_read;
logic [27:0] mem_pi_addr;
logic [31:0] mem_pi_readdata, mem_pi_writedata;

logic spi_clk, spi_cs, spi_mosi, spi_miso;
logic [31:0] spi_data;

assign spi_clk = GPIO_0[11];    // SCLK = pin 16 = GPIO_11
assign spi_cs = GPIO_0[9];	    // CS   = pin 14 = GPIO_9
assign spi_mosi = GPIO_0[15];	// MOSI = pin 20 = GPIO_15

assign GPIO_0[13] = spi_cs ? 1'bz : spi_miso;   // MISO = pin 18 = GPIO_13 // TODO useless ?

spi_slave spi_slave_instance(
	.SPI_CLK    (spi_clk),
	.SPI_CS     (spi_cs),
	.SPI_MOSI   (spi_mosi),
	.SPI_MISO   (spi_miso),
	.Data_WE    (mem_pi_we),
	.Data_Addr  (mem_pi_addr),
	.Data_Write (mem_pi_writedata),
	.Data_Read  (mem_pi_readdata),
	.mem_read(mem_pi_read),
	.Clk        (CLOCK_33),
	.reset(~KEY[0])
);

// SDRAM PLL
wire sdram_pll_clk;

sdram_pll sdram_pll_inst(
	.inclk0(CLOCK_50),
	.c0(sdram_pll_clk)
);

// SoPC instantiation
base u0 (
	// Main clock
   .clk_clk                            (CLOCK_50),
   .reset_reset_n                      (KEY[0]),
	// message pi
	.message_mem_s2_address   (message_addr),
	.message_mem_s2_writedata (message_wd),
	.message_mem_s2_readdata  (message_rd),
	.message_mem_s2_write     (message_we),
	.message_mem_s2_chipselect(1'b1),
	.message_mem_s2_clken(1'b1),
	.message_mem_s2_byteenable(4'b1111),
	// SDRAM
	.sdram_wire_addr (DRAM_ADDR),
	.sdram_wire_ba   (DRAM_BA),
	.sdram_wire_cas_n(DRAM_CAS_N),
	.sdram_wire_cke  (DRAM_CKE),
	.sdram_wire_cs_n (DRAM_CS_N),
	.sdram_wire_dq   (DRAM_DQ),
	.sdram_wire_dqm  (DRAM_DQM),
	.sdram_wire_ras_n(DRAM_RAS_N),
	.sdram_wire_we_n (DRAM_WE_N),
	// Display clock
	.clk_display_clk             (CLOCK_33),
	.reset_clk_display_reset_n   (KEY[0]),
	// Tiles pixel memory
	.tile_image_s2_address      (tiles_addr),
	.tile_image_s2_chipselect   (1'b1),
	.tile_image_s2_clken        (1'b1),
	.tile_image_s2_write        (1'b0),
	.tile_image_s2_readdata     (tiles_readdata),
	.tile_image_s2_writedata    (32'b0),
	.tile_image_s2_byteenable   (4'b1111),
	// Tiles indices memory
	.tile_idx_0_s2_address       (tiles_idx_0_addr),
	.tile_idx_0_s2_chipselect    (1'b1),
	.tile_idx_0_s2_clken         (1'b1),
	.tile_idx_0_s2_write         (tile_idx_0_we),
	.tile_idx_0_s2_readdata      (tiles_idx_0_readdata),
	.tile_idx_0_s2_writedata     (tile_idx_0_wd),
	.tile_idx_0_s2_byteenable    (4'b1111),
	.tile_idx_1_s2_address       (tiles_idx_1_addr),
	.tile_idx_1_s2_chipselect    (1'b1),
	.tile_idx_1_s2_clken         (1'b1),
	.tile_idx_1_s2_write         (tile_idx_1_we),
	.tile_idx_1_s2_readdata      (tiles_idx_1_readdata),
	.tile_idx_1_s2_writedata     (tile_idx_1_wd),
	.tile_idx_1_s2_byteenable    (4'b1111),
	// Colormap
	.colormap_s2_address    (colormap_addr),
	.colormap_s2_chipselect (1'b1),
	.colormap_s2_clken      (1'b1),
	.colormap_s2_write      (1'b0),
	.colormap_s2_readdata   (colormap_readdata),
	.colormap_s2_writedata  (32'b0),
	.colormap_s2_byteenable (4'b1111),
	// display control
	.display_control_external_connection_export(display_control),
	// mtl touch
	.mtl_touch_0_conduit_end_scl(MTL_TOUCH_I2C_SCL),
	.mtl_touch_0_conduit_end_sda(MTL_TOUCH_I2C_SDA),
	.mtl_touch_0_conduit_end_int_n(MTL_TOUCH_INT_n),
	// G Sensor
	.spi_gsensor_conduit_end_SDIO(I2C_SDAT),
	.spi_gsensor_conduit_end_SCLK(I2C_SCLK),
	.spi_gsensor_conduit_end_CS_n(G_SENSOR_CS_N),
	.int_gsensor_external_connection_export(G_SENSOR_INT)
);

assign DRAM_CLK = sdram_pll_clk;

// =============================================================
// =============================================================
// ======= Clock and Rest -- crazy stuff from altera ===========
// =============================================================
// =============================================================

// This PLL generates 33 MHz for the LCD screen. CLK_33 is used to generate the controls 
// while iCLK_33 is connected to the screen. Its phase is 120 so as to meet the setup and 
// hold timing constraints of the screen.
MTL_PLL	MTL_PLL_inst (
    .inclk0(CLOCK_50),
    .c0(CLOCK_33),	// 33MHz clock, phi=0
    .c1(CLOCK_33d)  // 33MHz clock, phi=120, unwired, where is useful?
);

assign MTL_DCLK = CLOCK_33d;

// Note: a critical warning is generated for the MTL_PLL:
// "input clock is not fully compensated because it is fed by
// a remote clock pin". In fact, each PLL can compensate the
// input clock on a set of dedicated pins.
// The input clock iCLK_50 (50MHz) should be available on other pins
// than PIN_R8 so that it can be compensated on each PLL, it is
// not the case in the DE0-Nano board.
// Hopefully, it is not important here.
//
// You might as well see three other critical warnings about 
// timing requirements. They are about communication between 
// iCLK (50MHz) and CLK_33. It is impossible to completely get 
// rid of them. They can be safely ignored as they aren't
// related to signals whose timing is critical. 

endmodule 

/*
 * This small module contains everything needed to synchronize
 * all the components after a reset.
 * If you don't use it, you can meet some random bugs after a reset.
 */
module	reset_delay (
	input  logic iRSTN,
	input  logic iCLK,
	output logic oRSTN,
	output logic oRD_RST,
	output logic oRST
	);
     
	reg  [26:0] cont;

	assign oRSTN    = |cont[26:20]; 
	assign oRD_RST  = cont[26:25] == 2'b01;      
	assign oRST     = !cont[26];  	

	always_ff @(posedge iCLK or negedge iRSTN)
		if (!iRSTN) 
			cont     <= 27'b0;
		else if (!cont[26]) 
			cont     <= cont + 27'b1;
  
endmodule
