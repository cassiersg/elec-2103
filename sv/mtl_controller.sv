
// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//  Ver  :| Author            	  :| Mod. Date :| Changes Made:
//  V1.0 :| Johnny Fan			     :| 07/06/30  :| Initial Revision
//	 V2.0 :| Charlotte Frenkel      :| 14/08/03  :| Adaptation for ELEC2103 project 
//  V3.0 :| Ludovic Moreau			  :| 17/02/06  :| Adaptation for ELEC2103 project
// --------------------------------------------------------------------

module mtl_controller (
	input 		iCLK,
	input 		iRST,
	// MTL
	output		 MTL_DCLK,				// LCD Display clock (to MTL)
	output		 MTL_HSD,				// LCD horizontal sync (to MTL) 
	output		 MTL_VSD,				// LCD vertical sync (to MTL)
	output		 MTL_TOUCH_I2C_SCL,  // I2C clock pin of Touch IC (from MTL)
	inout			 MTL_TOUCH_I2C_SDA,	// I2C data pin of Touch IC (from/to MTL)
	input			 MTL_TOUCH_INT_n,		// Interrupt pin of Touch IC (from MTL)
	output [7:0] MTL_R,					// LCD red color data  (to MTL)
	output [7:0] MTL_G,					// LCD green color data (to MTL)
	output [7:0] MTL_B 					// LCD blue color data (to MTL)
);

//=============================================================================
// REG/WIRE declarations
//=============================================================================

logic CLOCK_33, iCLOCK_33;						// 33MHz clocks for the MTL 

logic	newFrame, endFrame;

logic Gest_W, Gest_E;

logic [23:0]   ColorDataBfr, ColorData;	// {8-bit red, 8-bit green, 8-bit blue} 

 
//=============================================================================
// Structural coding
//=============================================================================

always @(posedge iCLK)
	if(iRST)					ColorDataBfr <= 24'd0;
	else if (Gest_W)		ColorDataBfr <= 24'hCC33FF;		// Purple
	else if (Gest_E)		ColorDataBfr <= 24'h33FF66;		// Green 
	else						ColorDataBfr <= ColorDataBfr;
	
always @(posedge iCLK)
	if(iRST)				 	ColorData <= 24'd0;
	else if (endFrame)	ColorData <= ColorDataBfr;			// Update the color displayed between 
	else						ColorData <= ColorData;				// two frames to avoid glitches

//=============================================================================
// Dedicated sub-controllers
//=============================================================================
 

//--- Display controller ------------------------------------

mtl_display_controller mtl_display_controller_inst (
	// Host Side
	.iCLK(CLOCK_33),				// Input LCD control clock
	.iRST_n(~iRST),				// Input system reset
	.iColorData(ColorData),		// Input hardcoded color data
	.oNewFrame(newFrame),		// Output signal being a pulse when a new frame of the LCD begins
	.oEndFrame(endFrame),		// Output signal being a pulse when a frame of the LCD ends
	// LCD Side
	.oLCD_R(MTL_R),				// Output LCD horizontal sync 
	.oLCD_G(MTL_G),				// Output LCD vertical sync
	.oLCD_B(MTL_B),				// Output LCD red color data 
	.oHD(MTL_HSD),					// Output LCD green color data 
	.oVD(MTL_VSD)					// Output LCD blue color data  
);

assign MTL_DCLK = iCLOCK_33;



//--- Touch controller -------------------------

mtl_touch_controller mtl_touch_controller_inst (
	.iCLK(iCLK),
	.iRST(iRST),
	// MTL TOUCH
	.MTL_TOUCH_INT_n(MTL_TOUCH_INT_n),		// Interrupt pin of Touch IC (from MTL)
	.MTL_TOUCH_I2C_SDA(MTL_TOUCH_I2C_SDA),	// I2C data pin of Touch IC (from/to MTL)
	.MTL_TOUCH_I2C_SCL(MTL_TOUCH_I2C_SCL),	// I2C clock pin of Touch IC (from MTL)
	// Gestures
	.Gest_W(Gest_W),								// Decoded gesture (sliding towards West)
	.Gest_E(Gest_E)								// Decoded gesture (sliding towards East)
);
			


//============================================================
// Clock management 
//============================================================

//This PLL generates 33 MHz for the LCD screen.
//CLOCK_33 is used to generate the controls while iCLOCK_33
//is connected to the screen. Its phase is 120 so as to
//meet the setup and hold timing constraints of the screen.
MTL_PLL	MTL_PLL_inst (
	.inclk0 (iCLK),
	.c0 (CLOCK_33),			//33MHz clock, phi=0
	.c1 (iCLOCK_33)			//33MHz clock, phi=120
);

/*
 * Note: a critical warning is generated for the MTL_PLL:
 * "input clock is not fully compensated because it is fed by
 * a remote clock pin". In fact, each PLL can compensate the
 * input clock on a set of dedicated pins.
 * The input clock iCLK (50MHz) should be available on other pins
 * than PIN_R8 so that it can be compensated on each PLL, it is
 * not the case in the DE0-Nano board.
 * Hopefully, it is not important here.
 *
 * You might as well see three other critical warnings about 
 * timing requirements. They are about communication between 
 * iCLK (50MHz) and CLOCK_33. It is impossible to completely get 
 * rid of them. They can be safely ignored as they aren't
 * related to signals whose timing is critical.
 */ 
 
endmodule // mtl_controller


