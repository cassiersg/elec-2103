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
	input           I2C_SDAT,

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

// MMU - MTL
logic [31:0] pixel_rgb;

logic next_display_active;

logic [31:0] pixel_readdata_1;
logic pixel_read_enable_1;
logic load_new_pixel_mem_1;
logic [23:0] pixel_base_address_1;
logic [23:0] pixel_max_address_1;


logic [31:0] pixel_readdata_2;
logic pixel_read_enable_2;
logic load_new_pixel_mem_2;
logic [23:0] pixel_base_address_2;
logic [23:0] pixel_max_address_2;
logic image_loaded;

// SPI outputs
logic Trigger;
logic [7:0] Img_Tot;
logic [23:0] Pix_Data;		

mmu mmu_inst(
    .iCLK_50(CLOCK_50),		// S:/ystem Clock (50MHz)
    .iCLK_33(CLOCK_33),		// MTL Clock (33 MHz, 0°)
    .iRST(dly_rst),			// System sync reset
    .iRd_RST(rd_rst),
    // SPI
    .iPix_Data(Pix_Data),	// Pixel's data from R-Pi (24-bit RGB)
    .iImg_Tot(Img_Tot),		// Total number of images transferred from Rasp-Pi
    .iTrigger(Trigger),		
    // MTL
    .i_load_new_1(load_new_pixel_mem_1),
    .iRead_En_1(pixel_read_enable_1), // SDRAM read control signal
    .i_base_address_1(pixel_base_address_1),
    .i_max_address_1(pixel_max_address_1),
    .oRead_Data_1(pixel_readdata_1), // Data (RGB) from SDRAM
    .i_load_new_2(load_new_pixel_mem_2),
    .iRead_En_2(pixel_read_enable_2), // SDRAM read control signal
    .i_base_address_2(pixel_base_address_2),
    .i_max_address_2(pixel_max_address_2),
    .oRead_Data_2(pixel_readdata_2), // Data (RGB) from SDRAM

    .o_image_loaded(image_loaded),
    // SDRAM
    .oDRAM_ADDR(DRAM_ADDR),
    .oDRAM_BA(DRAM_BA),
    .oDRAM_CAS_N(DRAM_CAS_N),
    .oDRAM_CKE(DRAM_CKE),
    .oDRAM_CLK(DRAM_CLK),
    .oDRAM_CS_N(DRAM_CS_N),
    .ioDRAM_DQ(DRAM_DQ),
    .oDRAM_DQM(DRAM_DQM),
    .oDRAM_RAS_N(DRAM_RAS_N),
    .oDRAM_WE_N(DRAM_WE_N)
);

// SPI
logic spi_clk, spi_cs, spi_mosi, spi_miso;
logic [31:0] spi_data;

assign spi_clk = GPIO_0[11];    // SCLK = pin 16 = GPIO_11
assign spi_cs = GPIO_0[9];	    // CS   = pin 14 = GPIO_9
assign spi_mosi = GPIO_0[15];	// MOSI = pin 20 = GPIO_15

assign GPIO_0[13] = spi_cs ? 1'bz : spi_miso;   // MISO = pin 18 = GPIO_13

// MTL
logic New_Frame;
logic End_Frame;

// MTL DISPLAY CONTROLLER
mtl_display_controller(
    .iCLK_50(CLOCK_50),
    .iCLK_33(CLOCK_33),
    .iRST(RST),
    .iImg_Tot(Img_Tot),
    .image_loaded(image_loaded),
    .iGest_E(Gest_E),
    .iGest_W(Gest_W),
    .iNew_Frame(New_Frame),
    .iEnd_Frame(End_Frame),
    .o_pixel_data(pixel_rgb),
    .i_next_active(next_display_active),
    // MMU
    .i_readdata_1(pixel_readdata_1),
    .o_load_new_1(load_new_pixel_mem_1),
    .o_read_enable_1(pixel_read_enable_1),
    .o_base_address_1(pixel_base_address_1),
    .o_max_address_1(pixel_max_address_1),
    .i_readdata_2(pixel_readdata_2),
    .o_load_new_2(load_new_pixel_mem_2),
    .o_read_enable_2(pixel_read_enable_2),
    .o_base_address_2(pixel_base_address_2),
    .o_max_address_2(pixel_max_address_2)
);

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
    .oVD(MTL_VSD)	// Output LCD blue color data  
);

logic Gest_W;
logic Gest_E;

// SoPC instantiation
base u0 (
    .clk_clk                            (CLOCK_50),
    .reset_reset_n                      (KEY[0]),
    // Trivial conduit for testing purposes
    .pio_0_external_connection_export   (32'd42),
    .mtl_touch_conduit_i2c_scl          (MTL_TOUCH_I2C_SCL),
	.mtl_touch_conduit_i2c_sda          (MTL_TOUCH_I2C_SDA),
	.mtl_touch_conduit_touch_int_n      (MTL_TOUCH_INT_n),
    .mtl_touch_conduit_gest_e           (Gest_E),  
    // Temporarily removed to test the MTL display IP
    //.mtl_touch_conduit_gest_w           (Gest_W),
    .mtl_display_ip_conduit_end_next_slide_pulse(Gest_W),

    .spi_slave_0_conduit_end_spi_clk      (spi_clk),
        .spi_slave_0_conduit_end_spii_cs  (spi_cs), 
        .spi_slave_0_conduit_end_mosi     (spi_mosi), 
        .spi_slave_0_conduit_end_miso     (spi_miso), 
        .spi_slave_0_conduit_end_img_tot  (Img_Tot), 
        .spi_slave_0_conduit_end_pix_data (Pix_Data), 
        .spi_slave_0_conduit_end_trigger  (Trigger)  
);

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
