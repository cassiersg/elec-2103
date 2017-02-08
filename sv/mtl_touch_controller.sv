

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

module mtl_touch_controller(
	input 	iCLK,
	input 	iRST,
	// MTL TOUCH
	input    MTL_TOUCH_INT_n,		// Interrupt pin of Touch IC (from MTL)
	inout 	MTL_TOUCH_I2C_SDA,	// I2C data pin of Touch IC (from/to MTL)
	output   MTL_TOUCH_I2C_SCL,	// I2C clock pin of Touch IC (from MTL)
	// Gestures
	output   Gest_W,					// Decoded gesture (sliding towards West)
	output   Gest_E					// Decoded gesture (sliding towards East)
);

//=============================================================================
// REG/WIRE declarations
//=============================================================================

logic [9:0] reg_x1, reg_x2, reg_x3, reg_x4, reg_x5;
logic [8:0] reg_y1, reg_y2, reg_y3, reg_y4, reg_y5;
logic [1:0] reg_touch_count;
logic [7:0] reg_gesture;
logic			touch_ready;


//=============================================================================
// Structural coding
//=============================================================================

// This touch controller, provided by Terasic, is encrypted.
// To be able to use it, a license must be added to the Quartus
// project (Tools > License Setup...).
// The license file 'license_multi_touch.dat' is given
// in the folder DE0_Nano/License.
// For details about the inputs and outputs, you can refer to
// section 3.3 of the MTL datasheet available in the project
// file folder.
i2c_touch_config  i2c_touch_config_inst (
	.iCLK(iCLK),
	.iRSTN(~iRST),
	.INT_n(~MTL_TOUCH_INT_n),
	.oREADY(touch_ready),
	.oREG_X1(reg_x1),								
	.oREG_Y1(reg_y1),								
	.oREG_X2(reg_x2),								
	.oREG_Y2(reg_y2),
	.oREG_X3(reg_x3),								
	.oREG_Y3(reg_y3),	
	.oREG_X4(reg_x4),								
	.oREG_Y4(reg_y4),
	.oREG_X5(reg_x5),								
	.oREG_Y5(reg_y5),
	.oREG_TOUCH_COUNT(reg_touch_count),								
	.oREG_GESTURE(reg_gesture),								
	.I2C_SCLK(MTL_TOUCH_I2C_SCL),
	.I2C_SDAT(MTL_TOUCH_I2C_SDA)
);


// These two modules are small buffers for the touch
// controller outputs.
// The first one is for the sliding "West" gesture,
// the second one for the sliding "East" gesture.
// More details are given while defining the module, please see below.

touch_buffer	touch_buffer_west (
	.clk (iCLK),
	.rst (iRST),
	.trigger (touch_ready && (reg_gesture == 8'h1C)),
	.pulse (Gest_W)
);

touch_buffer	touch_buffer_east (
	.clk (iCLK),
	.rst (iRST),
	.trigger (touch_ready && (reg_gesture == 8'h14)),
	.pulse (Gest_E)
);


endmodule // mtl_touch_controller


///////////////////////////////////////////////////////////////////////////


/*
 * This small counting module generates a one-cycle
 * pulse 0.2 secs after the rising edge of a trigger.
 * This module cannot be reactivated until 0.5 secs
 * have passed.
 * The time values are given for a 50 MHz input clock.
 * - 0.2 secs is short enough to bufferize the input of
 *   the touch controller while giving a fast response,
 * - 0.5 secs is for avoiding to skip two slides with
 *   a single touch.
 */
module touch_buffer (
	input  logic	clk,
	input  logic	rst,
	input  logic	trigger,
	output logic	pulse
	);

	logic active;
	logic [31:0] count;
	
	always_ff @ (posedge clk) begin
	
		if (rst) begin
			active <= 1'b0;
			count <= 32'd0;
		end else begin
			if (trigger && !active)
				active <= 1'b1;
			else if (active && (count < 32'd25000000))
				count <= count + 32'b1;
			else if (count >= 32'd25000000) begin
				active <= 1'b0;
				count <= 32'd0;
			end
		end
		
	end

	assign pulse = (count==32'd10000000); 
	
endmodule // touch_buffer