module mtl_display(
	// Host Side
	input			iCLK, 				// Input LCD control clock
	input			iRST_n, 			// Input system reset
	// MMU
	input 		    iLoading,			// Input signal telling in which loading state is the system
	input   [31:0]	iREAD_DATA,			// Input data from SDRAM (RGB)
	output			oREAD_SDRAM_EN,		// SDRAM read control signal
	output 			oNew_Frame,			// Output signal being a pulse when a new frame of the LCD begins
	output 			oEnd_Frame,			// Output signal being a pulse when a frame of the LCD ends
	// LCD Side
	output 		 	oHD,				// Output LCD horizontal sync 
	output 		 	oVD,				// Output LCD vertical sync 
	output  [7:0] 	oLCD_R,				// Output LCD red color data 
	output  [7:0] 	oLCD_G,           	// Output LCD green color data  
	output  [7:0] 	oLCD_B            	// Output LCD blue color data  
);
	
	//============================================================================
	// PARAMETER declarations
	//============================================================================

	// All these parameters are given in the MTL user manual, section 3.2,
	// available in the project file folder
	parameter H_LINE = 1056; 
	parameter V_LINE = 525;
	parameter Horizontal_Blank = 46;          //H_SYNC + H_Back_Porch
	parameter Horizontal_Front_Porch = 210;
	parameter Vertical_Blank = 23;      	   //V_SYNC + V_BACK_PORCH
	parameter Vertical_Front_Porch = 22;

	//=============================================================================
	// REG/WIRE declarations
	//=============================================================================
    //
	reg     [10:0]  x_cnt;  
	reg     [9:0]	y_cnt; 
	wire    [7:0]	read_red;
	wire    [7:0]	read_green;
	wire    [7:0]	read_blue; 
	wire			display_area, display_area_prev;
	//wire		   q_rom;
	wire    [18:0]  address;
	reg		        mhd;
	reg			    mvd;
	reg			    loading_buf;
	reg			    no_data_yet;

	//=============================================================================
	// Structural coding
	//=============================================================================

	//--- Assigning the right color data as a function -------------------------
	//--- of the current pixel position ----------------------------------------

	// This loading ROM contains B/W data to display the loading screen.
	// The data is available in the rom.mif file in the project folder.
	// Note that it is just a gadget for the demonstration, it is not efficient!
	// Indeed, it must contain 1bit x 800 x 480 = 384000 bits of data,
	// which is more than 60% of the total memory bits of the FPGA.
	// Don't hesitate to suppress it.
	/*Loading_ROM	Loading_ROM_inst (
		.address(address),
		.clock(iCLK),
		.q(q_rom),
		.rden(iLoading)
	);*/

	// This signal controls read requests to the SDRAM.
	// When asserted, new data becomes available in iREAD_DATA
	// at each clock cycle.
	assign	oREAD_SDRAM_EN = (~loading_buf && display_area_prev);
							
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
							
	// This signal updates the ROM address to read from based on the current pixel position.
	assign address = display_area_prev ? ((x_cnt-(Horizontal_Blank-2)) + (y_cnt-Vertical_Blank)*800) : 19'b0;

	// Assigns the right color data.
	always_ff @(posedge iCLK) begin
		// If the screen is reset, put at zero the color signals.
		if (!iRST_n) begin
			read_red 	<= 8'b0;
			read_green 	<= 8'b0;
			read_blue 	<= 8'b0;
		// If we are in the active display area...
		end else if (display_area) begin
			// ...and if no data has been sent yet by the Rasp-Pi,
			// then display a white screen.
			if (no_data_yet) begin
				read_red 	<= 8'd255;
				read_green 	<= 8'd255;
				read_blue 	<= 8'd255;
			// ...and if the slideshow is currently loading,
			// then display the loading screen.
			// The current pixel is black (resp. white)
			// if a 1 (resp. 0) is written in the ROM.
			end else if (loading_buf) begin
				read_red 	<= 8'd255;
				read_green 	<= 8'd255;
				read_blue 	<= 8'd255;
			// ...and if the slideshow has been loaded,
			// then display the values read from the SDRAM.
			end else begin
				read_red 	<= iREAD_DATA[23:16];
				read_green 	<= iREAD_DATA[15:8];
				read_blue 	<= iREAD_DATA[7:0];
			end
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
			x_cnt <= 11'd0;	
			mhd  <= 1'd0;  
		end	
		else if (x_cnt == (H_LINE-1))
		begin
			x_cnt <= 11'd0;
			mhd  <= 1'd0;
		end	   
		else
		begin
			x_cnt <= x_cnt + 11'd1;
			mhd  <= 1'd1;
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

	assign oNew_Frame = ((x_cnt == 11'd0)   && (y_cnt == 10'd0)  );	
	assign oEnd_Frame = ((x_cnt == 11'd846) && (y_cnt == 10'd503));	
		
		
	//--- Retrieving the current loading state based on the iLoading signal --------
		
	// - When iLoading is initially at 0, the Rasp-Pi has not sent anything yet, the 
	//   no_data_yet and loading_buf signals are at 1 and a white screen is displayed.
	// - When iLoading rises to 1, the slideshow is currently loading and no_data_yet
	//   falls at zero: the loading screen is displayed.
	// - When iLoading falls back to 0, the loading_buf signal falls at zero at the
	//   beginning of the next frame. The SDRAM data is then displayed.
	always@(posedge iCLK or negedge iRST_n) begin
		if (!iRST_n) begin
			no_data_yet <= 1'b1;
			loading_buf <= 1'b1;
		end else if (!iLoading && oNew_Frame && !no_data_yet) 
			loading_buf <= 1'b0;
		else if (iLoading)
			no_data_yet <= 1'b0;
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
	
							
endmodule // mtl_display
