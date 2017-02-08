
module DE0_NANO(

	//////////// CLOCK //////////
	CLOCK_50,

	//////////// LED //////////
	LED,

	//////////// KEY //////////
	KEY,

	//////////// SW //////////
	SW,

	//////////// SDRAM //////////
	DRAM_ADDR,
	DRAM_BA,
	DRAM_CAS_N,
	DRAM_CKE,
	DRAM_CLK,
	DRAM_CS_N,
	DRAM_DQ,
	DRAM_DQM,
	DRAM_RAS_N,
	DRAM_WE_N,

	//////////// EPCS //////////
	EPCS_ASDO,
	EPCS_DATA0,
	EPCS_DCLK,
	EPCS_NCSO,

	//////////// Accelerometer and EEPROM //////////
	G_SENSOR_CS_N,
	G_SENSOR_INT,
	I2C_SCLK,
	I2C_SDAT,

	//////////// ADC //////////
	ADC_CS_N,
	ADC_SADDR,
	ADC_SCLK,
	ADC_SDAT,

	//////////// 2x13 GPIO Header //////////
	GPIO_2,
	GPIO_2_IN,

	//////////// GPIO_0, GPIO_0 connects to GPIO Default //////////
	GPIO_0,
	GPIO_0_IN,

	//////////// GPIO_1, GPIO_1 connects to the MTL Screen //////////
	MTL_DCLK,
	MTL_HSD,
	MTL_VSD,
	MTL_TOUCH_I2C_SCL,
	MTL_TOUCH_I2C_SDA,
	MTL_TOUCH_INT_n,
	MTL_R,
	MTL_G,
	MTL_B
);

//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input 		          		CLOCK_50;

//////////// LED //////////
output		     [7:0]		LED;

//////////// KEY //////////
input 		     [1:0]		KEY;

//////////// SW //////////
input 		     [3:0]		SW;

//////////// SDRAM //////////
output		    [12:0]		DRAM_ADDR;
output		     [1:0]		DRAM_BA;
output		          		DRAM_CAS_N;
output		          		DRAM_CKE;
output		          		DRAM_CLK;
output		          		DRAM_CS_N;
inout 		    [15:0]		DRAM_DQ;
output		     [1:0]		DRAM_DQM;
output		          		DRAM_RAS_N;
output		          		DRAM_WE_N;

//////////// EPCS //////////
output		          		EPCS_ASDO;
input 		          		EPCS_DATA0;
output		          		EPCS_DCLK;
output		          		EPCS_NCSO;

//////////// Accelerometer and EEPROM //////////
output		          		G_SENSOR_CS_N;
input 		          		G_SENSOR_INT;
output		          		I2C_SCLK;
inout 		          		I2C_SDAT;

//////////// ADC //////////
output		          		ADC_CS_N;
output		          		ADC_SADDR;
output		          		ADC_SCLK;
input 		          		ADC_SDAT;

//////////// 2x13 GPIO Header //////////
inout 		    [12:0]		GPIO_2;
input 		     [2:0]		GPIO_2_IN;

//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
inout 		    [33:0]		GPIO_0;
input 		     [1:0]		GPIO_0_IN;

//////////// GPIO_1, GPIO_1 connect to the MTL Screen //////////
output							MTL_DCLK;
output							MTL_HSD;
output							MTL_VSD;
output							MTL_TOUCH_I2C_SCL;
inout								MTL_TOUCH_I2C_SDA;
input								MTL_TOUCH_INT_n;
output			  [7:0]		MTL_R;
output			  [7:0]		MTL_G;
output			  [7:0]		MTL_B;


//=======================================================
//  Structural coding
//=======================================================


//--- System Reset --------------------------------------
 
logic RST, dly_rstn, rd_rst, dly_rst;

assign RST = ~KEY[0];

// A good synchronization of all the resets of the different
// components must be carried out. Otherwise, some random bugs
// risk to appear after a reset of the system (see definition
// of the module at the end of this file).
reset_delay	reset_delay_inst (		
	.iRSTN(~RST),
   .iCLK(CLOCK_50),
	.oRSTN(dly_rstn),
	.oRD_RST(rd_rst),
	.oRST(dly_rst)
);


//--- MTL Controller ------------------------------------

mtl_controller (
	.iCLK(CLOCK_50),
	.iRST(dly_rst),
	// MTL
	.MTL_DCLK(MTL_DCLK),							// LCD Display clock (to MTL)
	.MTL_HSD(MTL_HSD),							// LCD horizontal sync (to MTL) 
	.MTL_VSD(MTL_VSD),							// LCD vertical sync (to MTL)
	.MTL_TOUCH_I2C_SCL(MTL_TOUCH_I2C_SCL), // I2C clock pin of Touch IC (from MTL)
	.MTL_TOUCH_I2C_SDA(MTL_TOUCH_I2C_SDA), // I2C data pin of Touch IC (from/to MTL)
	.MTL_TOUCH_INT_n(MTL_TOUCH_INT_n),     // Interrupt pin of Touch IC (from MTL)
	.MTL_R(MTL_R),									// LCD red color data  (to MTL)
	.MTL_G(MTL_G),									// LCD green color data (to MTL)
	.MTL_B(MTL_B) 									// LCD blue color data (to MTL)
);


endmodule // DE0_NANO


///////////////////////////////////////////////////////////////////////////


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

	assign oRSTN = |cont[26:20]; 
	assign oRD_RST = cont[26:25] == 2'b01;      
	assign oRST = !cont[26];  	

	always_ff @(posedge iCLK or negedge iRSTN)
		if (!iRSTN) 
			cont     <= 27'b0;
		else if (!cont[26]) 
			cont     <= cont + 27'b1;
  
endmodule // reset_delay

