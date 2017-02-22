
module mmu (
	input 			iCLK_50,			// System Clock (50MHz)
	input    		iCLK_33,			// MTL Clock (33 MHz, 0°)
    input 			iRST,				// System sync reset
	input			iRd_RST,
	// SPI
	input   [23:0]  iPix_Data,		// Pixel's data from R-Pi (24-bit RGB)
	input   [7:0]   iImg_Tot,		// Total number of images transferred from Rasp-Pi
	input 			iTrigger,	// Short pulse that is raised each time a whole pixel has been
								// received by the spi slave interface. Trigger enables writing 
								// the pixel to the SDRAM.
	// MTL
	output  [31:0]  oRead_Data,  // Data (RGB) from SDRAM to MTL controller
    input i_load_new,
	input 			iRead_En,	// SDRAM read control signal
    input logic [23:0] i_base_address,
    input logic [23:0] i_max_address,
    
    output logic image_loaded,

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
	logic 		    CLK_100, iCLK_100;
		
	logic 		    loading;
	logic	        wait_dly;
	logic   [5:0]   counter_dly;
	
	logic   [31:0]  counter_pix;

    // Active image loaded after receiving all pixels (+delay)
	always_ff @ (posedge iCLK_33, posedge iRST)
    begin
		if (iRST) begin
			image_loaded <= 1'b0;
			wait_dly    <= 1'b0;
			counter_dly <= 6'b0;
		end else begin
            // If we are at the end of the image acquisition
			if ((iImg_Tot > 0) && (counter_pix == (iImg_Tot*(32'd384000))))
            begin
                if (~image_loaded)
                begin
                    counter_dly <= counter_dly + 1'b1;
                end
            end
            if (counter_dly == 6'd50)
            begin
                image_loaded <= 1'b1;
            end
        end
    end
	
    // Receive pixels counter
	always_ff @(posedge iCLK_50, posedge iRST)
    begin
		if (iRST)
        begin
			counter_pix <= 32'b0;
		end else
        begin
			if (iTrigger)
				counter_pix <= counter_pix + 32'b1;
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
		.RD1_ADDR       (i_base_address),
		.RD1_MAX_ADDR   (i_max_address),
		.RD1_LENGTH     (RD_LENGTH),
		.RD1_LOAD       (iRST|| iRd_RST || i_load_new),
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
