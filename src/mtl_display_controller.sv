module mtl_display_controller(
	// Host Side
	input           iCLK, 			// Input LCD control clock
	input           iRST_n, 		// Input system reset
	input   [23:0]  iColorData,		// Input hardcoded color data
	output          oNewFrame,		// Output signal being a pulse when a new frame of the LCD begins
	output          oEndFrame,		// Output signal being a pulse when a frame of the LCD ends
	// LCD Side
	output          oHD,		    // Output LCD horizontal sync 
	output          oVD,			// Output LCD vertical sync 
	output  [7:0]   oLCD_R,			// Output LCD red color data 
	output  [7:0]   oLCD_G,         // Output LCD green color data  
	output  [7:0]   oLCD_B          // Output LCD blue color data  
);
		  
//============================================================================
// PARAMETER declarations
//============================================================================

// All these parameters are given in the MTL datasheet, section 3.2,
// available in the project file folder
parameter H_LINE = 1056; 
parameter V_LINE = 525;
parameter Horizontal_Blank = 46;            // H_SYNC + H_Back_Porch
parameter Horizontal_Front_Porch = 210;
parameter Vertical_Blank = 23;      	    // V_SYNC + V_BACK_PORCH
parameter Vertical_Front_Porch = 22;

//=============================================================================
// REG/WIRE declarations
//=============================================================================

reg     [10:0]  x_cnt;  
reg     [9:0]	y_cnt; 
wire    [7:0]	read_red;
wire    [7:0]	read_green;
wire    [7:0]	read_blue; 
wire			display_area, display_area_prev;
reg			    mhd;
reg			    mvd;

//=============================================================================
// Structural coding
//=============================================================================

//--- Assigning the right color data as a function -------------------------
//--- of the current pixel position ----------------------------------------
				
// This signal indicates the LCD active display area shifted back from
// 1 pixel in the x direction. This accounts for the 1-cycle delay
// in the sequential logic.
assign	display_area = ((x_cnt>(Horizontal_Blank-2)&&
						(x_cnt<(H_LINE-Horizontal_Front_Porch-1))&&
						(y_cnt>(Vertical_Blank-1))&& 
						(y_cnt<(V_LINE-Vertical_Front_Porch))));

// This signal indicates the same LCD active display area, now shifted
// back from 2 pixels in the x direction, again for sequential delays.
assign	display_area_prev =	((x_cnt>(Horizontal_Blank-3)&&
						(x_cnt<(H_LINE-Horizontal_Front_Porch-2))&&
						(y_cnt>(Vertical_Blank-1))&& 
						(y_cnt<(V_LINE-Vertical_Front_Porch))));	
						

// Assigns the right color data.
always_ff @(posedge iCLK) begin
	// If the screen is reset, put at zero the color signals.
	if (!iRST_n) begin
		read_red 	<= 8'b0;
		read_green 	<= 8'b0;
		read_blue 	<= 8'b0;
	// If we are in the active display area...
	end else if (display_area) begin
		read_red 	<= iColorData[23:16]; 
		read_green 	<= iColorData[15:8]; 
		read_blue 	<= iColorData[7:0];
	// If we aren't in the active display area, put at zero
	// the color signals.
	end else begin
		read_red 	<= 8'b0;
		read_green 	<= 8'b0;
		read_blue 	<= 8'b0;
	end
end

//--- Keeping track of x and y positions of the current pixel ------------------
//--- and generating the horiz. and vert. sync. signals ------------------------

always@(posedge iCLK or negedge iRST_n) begin
	if (!iRST_n)
	begin
		x_cnt   <= 11'd0;	
		mhd     <= 1'd0;  
	end	
	else if (x_cnt == (H_LINE-1))
	begin
		x_cnt   <= 11'd0;
		mhd     <= 1'd0;
	end	   
	else
	begin
		x_cnt   <= x_cnt + 11'd1;
		mhd     <= 1'd1;
	end	
end

always@(posedge iCLK or negedge iRST_n) begin
	if (!iRST_n)
		y_cnt <= 10'd0;
	else if (x_cnt == (H_LINE-1))
	begin
		if (y_cnt == (V_LINE-1))
			y_cnt <= 10'd0;
		else
			y_cnt <= y_cnt + 10'd1;	
	end
end

always@(posedge iCLK  or negedge iRST_n) begin
	if (!iRST_n)
		mvd  <= 1'b1;
	else if (y_cnt == 10'd0)
		mvd  <= 1'b0;
	else
		mvd  <= 1'b1;
end	

assign oNewFrame = ((x_cnt == 11'd0)   && (y_cnt == 10'd0)  );	
assign oEndFrame = ((x_cnt == 11'd846) && (y_cnt == 10'd503));	
	
//--- Assigning synchronously the color and sync. signals ------------------

always@(posedge iCLK or negedge iRST_n) begin
	if (!iRST_n)
		begin
			oHD	    <= 1'd0;
			oVD	    <= 1'd0;
			oLCD_R  <= 8'd0;
			oLCD_G  <= 8'd0;
			oLCD_B  <= 8'd0;
		end
	else
		begin
			oHD	    <= mhd;
			oVD	    <= mvd;
			oLCD_R  <= read_red;
			oLCD_G  <= read_green;
			oLCD_B  <= read_blue;
		end		
end
							
endmodule
