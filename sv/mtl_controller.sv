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
//  V1.0 :| Johnny Fan            :| 07/06/30  :| Initial Revision
//  V2.0 :| Charlotte Frenkel     :| 14/08/03  :| Adaptation for ELEC2103 project
//  V3.0 :| Ludovic Moreau        :| 17/02/06  :| Adaptation for ELEC2103 project
// --------------------------------------------------------------------

module mtl_controller (
    input logic iCLK,
    input logic iRST,
    // MTL
    output logic MTL_DCLK, // LCD Display clock (to MTL)
    output logic MTL_HSD, // LCD horizontal sync (to MTL)
    output logic MTL_VSD, // LCD vertical sync (to MTL)
    output logic [7:0] MTL_R, // LCD red color data  (to MTL)
    output logic [7:0] MTL_G, // LCD green color data (to MTL)
    output logic [7:0] MTL_B // LCD blue color data (to MTL)
);

//=============================================================================
// REG/WIRE declarations
//=============================================================================

logic CLOCK_33, iCLOCK_33; // 33MHz clocks for the MTL
logic newFrame, endFrame;
logic [23:0] ColorData, ColorDataBg; // {8-bit red, 8-bit green, 8-bit blue}

logic [9:0] curr_x;
logic [8:0] curr_y;

assign ColorDataBg = 24'h33FF66;

color_selector colsel(
    .bg_color(ColorDataBg),
    .fg_color(24'hFF0000),
    .input_valid(touch_ready),
    .nb_touch(reg_touch_count),
    .reg_x1(reg_x1),
    .reg_y1(reg_y1),
    .x_disp(curr_x),
    .y_disp(curr_y),
    .color(ColorData)
);

//--- Display controller ------------------------------------
mtl_display_controller mtl_display_controller_inst (
    // Host Side
    .iCLK(CLOCK_33), // Input LCD control clock
    .iRST_n(~iRST), // Input system reset
    .iColorData(ColorData), // Input hardcoded color data
    .oNewFrame(newFrame), // Output signal being a pulse when a new frame of the LCD begins
    .oEndFrame(endFrame), // Output signal being a pulse when a frame of the LCD ends
    // LCD Side
    .oLCD_R(MTL_R), // Output LCD horizontal sync
    .oLCD_G(MTL_G), // Output LCD vertical sync
    .oLCD_B(MTL_B), // Output LCD red color data
    .oHD(MTL_HSD), // Output LCD green color data
    .oVD(MTL_VSD), // Output LCD blue color data
    .curr_x(curr_x),
    .curr_y(curr_y)
);

assign MTL_DCLK = iCLOCK_33;

//--- Touch controller -------------------------
logic [9:0] reg_x1;
logic [8:0] reg_y1;
assign reg_x1 = 10'd200;
assign reg_y1 = 9'd200;
//============================================================
// Clock management
//============================================================

//This PLL generates 33 MHz for the LCD screen.
//CLOCK_33 is used to generate the controls while iCLOCK_33
//is connected to the screen. Its phase is 120 so as to
//meet the setup and hold timing constraints of the screen.
MTL_PLL	MTL_PLL_inst (
    .inclk0 (iCLK),
    .c0 (CLOCK_33), //33MHz clock, phi=0
    .c1 (iCLOCK_33) //33MHz clock, phi=120
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

module color_selector(
    input logic [23:0] bg_color,
    input logic [23:0] fg_color,
    input logic input_valid,
    input logic [1:0] nb_touch,
    input logic [9:0] reg_x1,
    input logic [8:0] reg_y1,
    input logic [9:0] x_disp,
    input logic [8:0] y_disp,
    output logic [23:0] color
);

logic [6:0] margin;
assign margin = 7'd20;

always_comb
begin
    if
    ((x_disp > reg_x1 - margin & x_disp < reg_x1 + margin) &
    (y_disp > reg_y1 - margin & y_disp < reg_y1 + margin))
    begin
        color = fg_color;
    end
    else
    begin
        color = bg_color;
    end
end

endmodule

