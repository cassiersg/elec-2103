module mtl_display(
	// Host Side
	input			iCLK, 				// Input LCD control clock
	input			iRST_n, 			// Input system reset
	// MMU
	input   [31:0]	iREAD_DATA,			// Input data from SDRAM (RGB)
	output			next_display_active,		// SDRAM read control signal
	output 			oNew_Frame,			// Output signal being a pulse when a new frame of the LCD begins
	output 			oEnd_Frame,			// Output signal being a pulse when a frame of the LCD ends
	// LCD Side
	output 		 	oHD,				// Output LCD horizontal sync 
	output 		 	oVD,				// Output LCD vertical sync 
	output  [7:0] 	oLCD_R,				// Output LCD red color data 
	output  [7:0] 	oLCD_G,           	// Output LCD green color data  
	output  [7:0] 	oLCD_B,            	// Output LCD blue color data

    output [10:0] o_next2_x,
    output [9:0] o_next2_y
);
	
	//============================================================================
	// PARAMETER declarations
	//============================================================================

	// All these parameters are given in the MTL user manual, section 3.2,
	// available in the project file folder
	parameter H_LINE = 1056; 
	parameter V_LINE = 525;
	parameter Horizontal_Blank = 46;        // H_SYNC + H_Back_Porch
	parameter Horizontal_Front_Porch = 210;
	parameter Vertical_Blank = 23;          // V_SYNC + V_BACK_PORCH
	parameter Vertical_Front_Porch = 22;

	//=============================================================================
	// REG/WIRE declarations
	//=============================================================================
    //
	logic [10:0] x_cnt, x_next;  
	logic [9:0]	y_cnt, y_next; 
	logic [7:0]	read_red, read_green, read_blue;
	logic mhd, mvd;
	logic current_display_active;

	logic [11:0] next2_x_unmasked;
	logic [10:0] next2_y_unmasked;
	assign next2_x_unmasked = x_next - Horizontal_Blank - 11'b1;
	assign next2_y_unmasked = y_next - Vertical_Blank;
	assign o_next2_x = next2_x_unmasked >= 800 ? 11'b0 : next2_x_unmasked;
   assign o_next2_y = next2_y_unmasked >= 480 ? 11'b0 : next2_y_unmasked;
	
	assign next_display_active = (
			(x_next >= Horizontal_Blank) &&
			(x_next < Horizontal_Blank + 800 ) &&
			(y_next >= Vertical_Blank ) &&
			(y_next < Vertical_Blank + 480));
	assign current_display_active = next_display_active;
	
	// approximative, but doesn't matter (for now)
	assign oNew_Frame = ((x_next == 11'd0)   && (y_next == 10'd0)  );	
	assign oEnd_Frame = ((x_next == 11'd846) && (y_next == 10'd503));
							
							
	// Assigns the right color data.
	always_comb
    begin
		// If the screen is reset, put at zero the color signals.
		if (!iRST_n)
        begin
			read_red 	= 8'b0;
			read_green 	= 8'b0;
			read_blue 	= 8'b0;
		end
        else if (current_display_active) // needed because screen is 480x801 pixels...
        begin
            read_red 	= iREAD_DATA[23:16];
            read_green 	= iREAD_DATA[15:8];
            read_blue 	= iREAD_DATA[7:0];
        end
		 else
		 begin
			read_red 	= 8'b0;
			read_green 	= 8'b0;
			read_blue 	= 8'b0;
		end
	end

	//--- Keeping track of x and y positions of the current pixel ------------------
	//--- and generating the horiz. and vert. sync. signals ------------------------

	always@(posedge iCLK or negedge iRST_n) begin
		if (!iRST_n) x_next <= 11'd0;	
		else if (x_next == (H_LINE-1)) x_next <= 11'd0;
		else x_next <= x_next + 11'd1;
	end
	
	always_ff @(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n) mhd <= 1'b0;
		else if (x_cnt == 0) mhd <= 1'b0;
		else mhd <= 1'b1;
	end

	always@(posedge iCLK or negedge iRST_n) begin
		if (!iRST_n)
			y_next <= 10'd0;
		else if (x_next == (H_LINE-1))
		begin
			if (y_next == (V_LINE-1))
				y_next <= 10'd0;
			else
				y_next <= y_next + 10'd1;	
		end
	end

	always@(posedge iCLK  or negedge iRST_n) begin
		if (!iRST_n) mvd  <= 1'b1;
		else if (y_cnt == 10'd0) mvd  <= 1'b0;
		else mvd  <= 1'b1;
	end	

	always_ff @(posedge iCLK)
	begin
		x_cnt <= x_next;
		y_cnt <= y_next;
	end	

	//--- Assigning synchronously the color and sync. signals ------------------

	always@(posedge iCLK or negedge iRST_n) begin
		if (!iRST_n)
			begin
				oHD	<= 1'd0;
				oVD	<= 1'd0;
				oLCD_R <= 8'd0;
				oLCD_G <= 8'd0;
				oLCD_B <= 8'd0;
			end
		else
			begin
				oHD	<= mhd;
				oVD	<= mvd;
				oLCD_R <= read_red;
				oLCD_G <= read_green;
				oLCD_B <= read_blue;
			end		
	end
endmodule
