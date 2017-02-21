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

//=======================================================
//  Structural coding
//=======================================================

// System Reset
 
logic RST, dly_rstn, rd_rst, dly_rst;

assign RST = ~KEY[0];

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

base u0 (
    .clk_clk                          (CLOCK_50),
    .reset_reset_n                    (KEY[0]),
    // Trivial conduit for testing purposes
    .pio_0_external_connection_export (32'd42),
    .mtl_touch_conduit_i2c_scl        (MTL_TOUCH_I2C_SCL),
	.mtl_touch_conduit_i2c_sda        (MTL_TOUCH_I2C_SDA),
	.mtl_touch_conduit_touch_int_n    (MTL_TOUCH_INT_n)
);

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
