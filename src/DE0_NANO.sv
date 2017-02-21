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

// System clock and 
logic ClOCK_33;
logic RST, dly_rstn, rd_rst, dly_rst;

// Synchronous system reset from R-PI
assign RST = GPIO_0[1];

// MMU - MTL
logic [31:0]	SDRAM_RData;
logic 			SDRAM_REn;
logic			New_Frame, End_Frame;

logic 			Gest_W, Gest_E;
logic 			Loading;

// Pixel's RGB data
logic			Trigger;
logic [7:0] 	Img_Tot;
logic [23:0] 	Pix_Data;		

// SPI
logic 			spi_clk, spi_cs, spi_mosi, spi_miso;
logic [31:0]	spi_data;

// A good synchronization of all the resets of the different
// components must be carried out. Otherwise, some random bugs
// risk to appear after a reset of the system (see definition
// of the module at the end of this file).
// TODO: get rid of this?
reset_delay	reset_delay_inst (		
    .iRSTN  (~RST),
    .iCLK   (CLOCK_50),
	.oRSTN  (dly_rstn),
	.oRD_RST(rd_rst),
	.oRST   (dly_rst)
);

/****************************/
/*  Memory Management Unit  */
/****************************/

mmu mmu_inst(
    .iCLK_50(CLOCK_50),		// System Clock (50MHz)
    .iCLK_33(CLOCK_33),		// MTL Clock (33 MHz, 0°)
    .iRST(dly_rst),			// System sync reset
    .iRd_RST(rd_rst),
    
    // SPI
    .iPix_Data(Pix_Data),	// Pixel's data from R-Pi (24-bit RGB)
    .iImg_Tot(Img_Tot),		// Total number of images transferred from Rasp-Pi
    /* Short pulse that is raised each time a whole pixel has been
    received by the spi slave interface. Trigger enables writing the pixel
    to the SDRAM.*/
    .iTrigger(Trigger),		

    // MTL
    .iGest_W(Gest_W),
    .iGest_E(Gest_E),
	// Control signal being a pulse when a new frame of the LCD begins
    .iNew_Frame(New_Frame),
    // Control signal being a pulse when a frame of the LCD ends        
    .iEnd_Frame(End_Frame),
	// Control signal telling in which loading state is the system
    .oLoading(Loading),		
    .oRead_Data(SDRAM_RData),   // Data (RGB) from SDRAM to MTL controller
    .iRead_En(SDRAM_REn),		// SDRAM read control signal

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

/********************/
/*  LCD controller  */
/********************/
	
mtl_controller mtl_ctrl_inst(
    .iCLK_50(CLOCK_50),				// System clock (50MHz)
    .iRST(dly_rst),					// System sync reset
    .oCLK_33(CLOCK_33),				// MTL Clock (33 MHz, 0°)
    // MMU
    // Input signal telling in which loading state is the system 
    .iLoading(Loading),
    .iREAD_DATA(SDRAM_RData), 		// Input data from SDRAM (RGB)
    .oREAD_SDRAM_EN(SDRAM_REn),		// SDRAM read control signal
    // Output signal being a pulse when a new frame of the LCD begins
    .oNew_Frame(New_Frame),
	// Output signal being a pulse when a frame of the LCD ends
    .oEnd_Frame(End_Frame),
    // MTL
    .oMTL_DCLK(MTL_DCLK),			// LCD Display clock (to MTL)
    .oMTL_HSD(MTL_HSD),			    // LCD horizontal sync (to MTL) 
    .oMTL_VSD(MTL_VSD),				// LCD vertical sync (to MTL)
    .oMTL_R(MTL_R),					// LCD red color data  (to MTL)
    .oMTL_G(MTL_G),					// LCD green color data (to MTL)
    .oMTL_B(MTL_B) 					// LCD blue color data (to MTL)
);

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
    .mtl_touch_conduit_gest_w           (Gest_W)
);


/*************************/
/*  SPI slave interface  */
/*************************/

spi_slave spi_slave_inst(
    .iCLK           (CLOCK_50),		// System clock (50MHz)
    .iRST	        (dly_rst),		// System sync reset
    // SPI
    .iSPI_CLK       (spi_clk),		// SPI clock
    .iSPI_CS        (spi_cs),		// SPI chip select
    .iSPI_MOSI      (spi_mosi),		// SPI MOSI (from Rasp-Pi)
    .oSPI_MISO      (spi_miso),		// SPI MISO (to Rasp-Pi)
    // Internal registers R/W
    // Write enable for SPI internal registers (not used here)
    .iData_WE       (1'b0),
	// Write address for SPI internal registers (not used here)
    .iData_Addr     (32'd0),
	// Write data for SPI internal registers (not used here)
    .iData_Write    (32'd0),
	// Read data from SPI internal registers (not used here)
    .oData_Read     (spi_data),
    // MTL
    .oPix_Data      (Pix_Data),		// Pixel's data from R-Pi (24-bit RGB)
    .oImg_Tot       (Img_Tot),		// Total number of images transferred from Rasp-Pi
    .oTrigger       (Trigger)		
);

assign spi_clk  = GPIO_0[11];				    // SCLK = pin 16 = GPIO_11
assign spi_cs   = GPIO_0[9];					// CS   = pin 14 = GPIO_9
assign spi_mosi = GPIO_0[15];					// MOSI = pin 20 = GPIO_15

assign GPIO_0[13] = spi_cs ? 1'bz : spi_miso;   // MISO = pin 18 = GPIO_13

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
