module mtl_controller (
	input 		    iCLK_50,				// System clock (50MHz)
	input 		    iRST,					// System sync reset
	output          oCLK_33,				// MTL Clock (33 MHz, 0°)
	// MMU 
	input 		    iLoading,				// Control signal telling in which loading state is the system
	input   [31:0]  iREAD_DATA, 			// Data (RGB)from SDRAM to MTL
	output          oREAD_SDRAM_EN,		    // SDRAM read control signal
	output		    oNew_Frame,			    // Control signal being a pulse when a new frame of the LCD begins
	output		    oEnd_Frame,			    // Control signal being a pulse when a frame of the LCD ends
	// MTL
	output		    oMTL_DCLK,				// LCD Display clock (to MTL)
	output		    oMTL_HSD,				// LCD horizontal sync (to MTL) 
	output		    oMTL_VSD,				// LCD vertical sync (to MTL)
	output [7:0]    oMTL_R,				    // LCD red color data  (to MTL)
	output [7:0]    oMTL_G,				    // LCD green color data (to MTL)
	output [7:0]    oMTL_B 				    // LCD blue color data (to MTL)
);

	//=============================================================================
	// REG/WIRE declarations
	//=============================================================================

	logic CLK_33, iCLK_33;					// 33MHz clocks for the MTL 

	//=============================================================================
	// Structural coding
	//=============================================================================

	/************************/
	/*  Display management  */
	/************************/

	mtl_display mtl_display_inst (
	    // Host Side
		.iCLK(CLK_33),						// Input LCD control clock
		.iRST_n(~iRST),						// Input system reset
		// MMU
		.iLoading(iLoading),				// Control signal telling in which loading state is the system
		.iREAD_DATA(iREAD_DATA),			// Input data from SDRAM (RGB)
		.oREAD_SDRAM_EN(oREAD_SDRAM_EN),	// SDRAM read control signal
		.oNew_Frame(oNew_Frame),			// Output signal being a pulse when a new frame of the LCD begins
		.oEnd_Frame(oEnd_Frame),			// Output signal being a pulse when a frame of the LCD ends
		// LCD Side
		.oLCD_R(oMTL_R),					// Output LCD horizontal sync 
		.oLCD_G(oMTL_G),					// Output LCD vertical sync
		.oLCD_B(oMTL_B),					// Output LCD red color data 
		.oHD(oMTL_HSD),						// Output LCD green color data 
		.oVD(oMTL_VSD)						// Output LCD blue color data  
	);

	assign oMTL_DCLK = iCLK_33;

	/**********************/
	/*  Clock management  */ 
	/**********************/

	// This PLL generates 33 MHz for the LCD screen. CLK_33 is used to generate the controls 
	// while iCLK_33 is connected to the screen. Its phase is 120 so as to meet the setup and 
	// hold timing constraints of the screen.
	MTL_PLL	MTL_PLL_inst (
		.inclk0 (iCLK_50),
		.c0 (CLK_33),	    // 33MHz clock, phi=0
		.c1 (iCLK_33)		// 33MHz clock, phi=120
	);
	
	assign  oCLK_33 = CLK_33;

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

