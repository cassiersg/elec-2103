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
    output logic MTL_TOUCH_I2C_SCL, // I2C clock pin of Touch IC (from MTL)
    inout MTL_TOUCH_I2C_SDA, // I2C data pin of Touch IC (from/to MTL)
    input MTL_TOUCH_INT_n, // Interrupt pin of Touch IC (from MTL)
    output logic [7:0] MTL_R, // LCD red color data  (to MTL)
    output logic [7:0] MTL_G, // LCD green color data (to MTL)
    output logic [7:0] MTL_B, // LCD blue color data (to MTL)
    // SPI
    input logic SPI_CLK,
    input logic SPI_MOSI,
    input logic SPI_CS,
    output logic SPI_MISO
);

//=============================================================================
// REG/WIRE declarations
//=============================================================================

logic CLOCK_33, iCLOCK_33; // 33MHz clocks for the MTL
logic newFrame, endFrame;
logic Gest_N, Gest_S, Gest_W, Gest_E;
logic [23:0] ColorData, ColorDataBfr, ColorDataBg; // {8-bit red, 8-bit green, 8-bit blue}

logic [9:0] curr_x;
logic [8:0] curr_y;

//=============================================================================
// Structural coding
//=============================================================================

always @(posedge iCLK)
if(iRST)
    ColorDataBfr <= 24'd0;
else if (Gest_W)
    ColorDataBfr <= 24'hCC33FF; // Purple
else if (Gest_E)
    ColorDataBfr <= 24'h33FF66; // Green
else if (Gest_N)
    ColorDataBfr <= 24'hFF2266; // 
else if (Gest_S)
    ColorDataBfr <= 24'h11AAEE; // 
else
    ColorDataBfr <= ColorDataBfr;

always @(posedge iCLK)
if(iRST)
    ColorDataBg <= 24'd0;
else if (endFrame)
    ColorDataBg <= ColorDataBfr; // Update the color displayed between
else
    ColorDataBg <= ColorDataBg; // two frames to avoid glitches

//=============================================================================
// Dedicated sub-controllers
//=============================================================================

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
logic [9:0] reg_x1, reg_x2, reg_x3, reg_x4, reg_x5;
logic [8:0] reg_y1, reg_y2, reg_y3, reg_y4, reg_y5;
logic [1:0] reg_touch_count;
logic [7:0] reg_gesture;
logic touch_ready;
mtl_touch_controller mtl_touch_controller_inst (
    .iCLK(iCLK),
    .iRST(iRST),
    // MTL TOUCH
    .MTL_TOUCH_INT_n(MTL_TOUCH_INT_n), // Interrupt pin of Touch IC (from MTL)
    .MTL_TOUCH_I2C_SDA(MTL_TOUCH_I2C_SDA), // I2C data pin of Touch IC (from/to MTL)
    .MTL_TOUCH_I2C_SCL(MTL_TOUCH_I2C_SCL), // I2C clock pin of Touch IC (from MTL)
    // Gestures
    .Gest_W(Gest_W), // Decoded gesture (sliding towards West)
    .Gest_E(Gest_E), // Decoded gesture (sliding towards East)
    .Gest_N(Gest_N), // Decoded gesture (sliding towards North)
    .Gest_S(Gest_S), // Decoded gesture (sliding towards South)
    // Debug
    .reg_x1(reg_x1),
    .reg_x2(reg_x2),
    .reg_x3(reg_x3),
    .reg_x4(reg_x4),
    .reg_x5(reg_x5),
    .reg_y1(reg_y1),
    .reg_y2(reg_y2),
    .reg_y3(reg_y3),
    .reg_y4(reg_y4),
    .reg_y5(reg_y5),
    .reg_touch_count(reg_touch_count),
    .reg_gesture(reg_gesture),
    .touch_ready(touch_ready)
);

// SPI
logic [3:0] dbg_counter;
logic [31:0] dbg_data;

always_ff @(posedge iCLK, posedge iRST)
begin
    if (iRST)
        dbg_counter <= 4'b0;
    else if (dbg_counter == 4'd12)
        dbg_counter <= 4'b0;
    else
        dbg_counter <= dbg_counter + 4'b1;
end

always_comb
case (dbg_counter)
    4'd0: dbg_data = {22'b0, reg_x1};
    4'd1: dbg_data = {22'b0, reg_x2};
    4'd2: dbg_data = {22'b0, reg_x3};
    4'd3: dbg_data = {22'b0, reg_x4};
    4'd4: dbg_data = {22'b0, reg_x5};
    4'd5: dbg_data = {23'b0, reg_y1};
    4'd6: dbg_data = {23'b0, reg_y2};
    4'd7: dbg_data = {23'b0, reg_y3};
    4'd8: dbg_data = {23'b0, reg_y4};
    4'd9: dbg_data = {23'b0, reg_y5};
    4'd10: dbg_data = {30'b0, reg_touch_count};
    4'd11: dbg_data = {24'b0, reg_gesture};
    4'd12: dbg_data = {31'b0, touch_ready};
    default: dbg_data = 32'hffffffff;
endcase

spi_slave spi_slave_instance(
    .SPI_CLK(SPI_CLK),
    .SPI_MISO(SPI_MISO),
    .SPI_MOSI(SPI_MOSI),
    .SPI_CS(SPI_CS),
    .Data_WE(touch_ready),
    .Data_Addr({26'b0, dbg_counter, 2'b0}),
    .Data_Write(dbg_data),
    .Clk(iCLK)
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

