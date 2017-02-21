//-------------------------------------------------------------
// Memory Management Unit
//-------------------------------------------------------------

/*
    Short explanation: the MMU provides an interface between:
    1) The SPI and the SDRAM, allowing the SPI to write in the SDRAM
    via the SDRAM contoller.
    2) The MTL TOUCH CONTROLLER and the SDRAM. Given a gesture sent by
    the MTL TOUCH CONTROLLER, change the base/max read address and the
    read enable signal of the SDRAM.

    @cassiers: do you confirm this?
*/ 

module mmu (
	input 			iCLK_50,			// System Clock (50MHz)
	input    		iCLK_33,			// MTL Clock (33 MHz, 0°)
    input 			iRST,				// System sync reset
	input			iRd_RST,
	// SPI
	input   [23:0]  iPix_Data,			// Pixel's data from R-Pi (24-bit RGB)
	input   [7:0]   iImg_Tot,			// Total number of images transferred from Rasp-Pi
	input 			iTrigger,			// Short pulse that is raised each time a whole pixel has been
										// received by the spi slave interface. Trigger enables writing 
										// the pixel to the SDRAM.
	// MTL
	input           iGest_E,
	input  			iGest_W,
	input           iNew_Frame,			// Control signal being a pulse when a new frame of the LCD begins
	input           iEnd_Frame,			// Control signal being a pulse when a frame of the LCD ends
	output          oLoading,			// Control signal telling in which loading state is the system
	output  [31:0]  oRead_Data,    	    // Data (RGB) from SDRAM to MTL controller
	input 			iRead_En,			// SDRAM read control signal
	// SDRAM
	output  [12:0]	oDRAM_ADDR,
	output  [1:0]	oDRAM_BA,
	output  		oDRAM_CAS_N,
	output  		oDRAM_CKE,
	output  	    oDRAM_CLK,
	output  		oDRAM_CS_N,
	inout   [15:0]  ioDRAM_DQ,
	output  [1:0]	oDRAM_DQM,
	output  		oDRAM_RAS_N,
	output  		oDRAM_WE_N
	
);

	//==================================================================================
	//  PARAMETER declarations
	//==================================================================================

	//Parameters for the SDRAM Controller
	parameter	WR_LENGTH       = 9'h2;
	parameter	RD_LENGTH       = 9'h80;
	parameter	RANGE_ADDR_IMG	= 23'd768000;

	//- WR_LENGTH is 2 for writing pixel per pixel as soon as one is received via SPI
	//				 (it accounts for the fact that the SDRAM has a 16-bit bus and not 32-bit,
	//				  please refer to the introductory slides).
	//- RD_LENGTH is a high number for acquiring sufficient data from the SDRAM and
	//				  storing it in the read FIFO in advance, enough data will then be
	//				  available at each clock cycle of CLOCK_33 to update the screen.
	//- RANGE_ADDR_IMG is equal to 480x800 times 2 (again for 32-bit vs 16-bit bus).

	//=============================================================================
	// REG/WIRE declarations
	//=============================================================================
	
	logic 		    CLK_100, iCLK_100;
		
	logic 		    loading;
	logic	        wait_dly;
	logic   [5:0]   counter_dly;
	
	logic   [23:0]  base_read_addr, max_read_addr;
	logic   [4:0]   current_img;
	logic			load_new;
	logic   [31:0]  counter_pix;
	
	//=============================================================================
	// Structural coding
	//=============================================================================
	
	// The loading signal tells the LCD controller where it should
	// take its inputs from (see the code of the controller for details).
	// 1.  loading is at 0, no valid data has been received yet from
	//     the Rasp-Pi.
	// 2.  loading is put at 1, the acquisition of the images of the
	//	   slideshow has begun.
	// 3.  loading is put back at 0, acquisition is over.
	always_ff @ (posedge iCLK_33, posedge iRST) begin
		if (iRST) begin
			loading     <= 1'b0;
			wait_dly    <= 1'b0;
			counter_dly <= 6'b0;
		end else begin
            // If we are at the end of the image acquisition
			if ((iImg_Tot > 0) && (counter_pix == (iImg_Tot*(32'd384000))))
				wait_dly    <= 1'b1;
			else if (counter_pix > 32'b0)
				loading     <= 1'b1;

            // Kind of a "dead time zone" between the end of the acquisition
            // and the end of the loading screen?
			if (wait_dly)
				if (counter_dly <= 6'd50)
					counter_dly <= counter_dly + 1'b1;
				else
					loading     <= 1'b0;
		end
	end
	
	assign oLoading = loading;
	 
	// Pixel counter :
	// When all the images will be acquired, it will 
	// listen to the (buffered) touch controller signals so
	// as to switch images when required by the user.
	always_ff @(posedge iCLK_50, posedge iRST) begin
		if (iRST) begin
			current_img <= 5'b0;
			counter_pix <= 32'b0;
		end else begin
			if (iTrigger)
				counter_pix <= counter_pix + 32'b1;
			
            // If we are at the end of the image acquisition
			if ((iImg_Tot > 0) && (counter_pix == (iImg_Tot*(32'd384000))))
				if (iGest_E)
                    // Wrap around between slides
					if (current_img == 5'b0)
						current_img <= iImg_Tot[4:0] - 5'b1;
					else
						current_img <= current_img - 5'b1;
				else if (iGest_W)
					if (current_img == (iImg_Tot[4:0] - 5'b1))
						current_img <= 5'b0;
					else
						current_img <= current_img + 5'b1;		
		end
	end

	// This always block is synchronous with the LCD controller
	// and with the read side of the SDRAM controller.
	// Based on the current image, the base and max read
	// addresses are updated each time a frame ends, the
	// read FIFO is emptied as well when a new frame begins.
	// The signals End_Frame and New_Frame come from the LCD controller.
	always_ff @(posedge iCLK_33, posedge iRST) begin
		if (iRST) begin
			base_read_addr 	<= 24'b0;
			max_read_addr 	<= RANGE_ADDR_IMG;
			load_new 		<= 1'b0;
		end else begin
			if (iEnd_Frame) begin
				base_read_addr <= current_img*RANGE_ADDR_IMG;
				max_read_addr  <= current_img*RANGE_ADDR_IMG + RANGE_ADDR_IMG;
			end else begin
                // FIXME: useless I suppose?
				base_read_addr <= base_read_addr;
				max_read_addr  <= max_read_addr;
			end
			
			load_new <= iNew_Frame;
		end
	end
	
	/**********************/
	/*  SDRAM Controller  */
	/**********************/
	
	// NB : only one R & W FIFO used here. Two more
	// are available (cf. sdram_control.v)
	sdram_control sdram_control_inst (							
		.RESET_N        (~iRST),
		.CLK            (CLK_100),
		//	FIFO Write Side 1
		.WR1_DATA       ({8'b0, iPix_Data[23:16], iPix_Data[15:8], iPix_Data[7:0]}), 	// {-,R,G,B}
		.WR1            (iTrigger),
		.WR1_ADDR       (0),
		.WR1_MAX_ADDR   (iImg_Tot*RANGE_ADDR_IMG),
		.WR1_LENGTH     (WR_LENGTH),
		.WR1_LOAD       (iRST),
		.WR1_CLK        (~iCLK_50),
		//	FIFO Read Side 1
		.RD1_DATA       (oRead_Data),
		.RD1            (iRead_En),
		.RD1_ADDR       (base_read_addr),
		.RD1_MAX_ADDR   (max_read_addr),
		.RD1_LENGTH     (RD_LENGTH),
		.RD1_LOAD       (iRST|| iRd_RST || load_new),
		.RD1_CLK        (iCLK_33),
		//	SDRAM 
		.SA             (oDRAM_ADDR),
		.BA             (oDRAM_BA),
		.CS_N           (oDRAM_CS_N),
		.CKE            (oDRAM_CKE),
		.RAS_N          (oDRAM_RAS_N),
		.CAS_N          (oDRAM_CAS_N),
		.WE_N           (oDRAM_WE_N),
		.DQ             (ioDRAM_DQ),
		.DQM            (oDRAM_DQM)
	);
	
	assign oDRAM_CLK = iCLK_100;
	
	/**********************/
	/*  Clock management  */ 
	/**********************/

	//	This PLL generates 100 MHz for the SDRAM.
	//	CLK_100 used to generate the controls while iCLK_100
	//	is connected to the SDRAM. Its phase is -108 so as to
	//	meet the setup and hold timing constraints of the SDRAM.
	RAM_PLL	RAM_PLL_inst (
		.inclk0 (iCLK_50),
		.c0 (CLK_100),			//100MHz clock, phi=0
		.c1 (iCLK_100)			//100MHz clock, phi=-108
	);	 
	
endmodule 
