module mtl_display_controller (
    // global system
	input 			iCLK_50,			// System Clock (50MHz)
	input    		iCLK_33,	// MTL Clock (33 MHz, 0°)
    input 			iRST,				// System sync reset
	// SPI
	input   [7:0]   iImg_Tot,			// Total number of images transferred from Rasp-Pi
    input           image_loaded,
    // Temp
	input           iGest_E,
	input  			iGest_W,
	// mtl_display
	input  iNew_Frame, // Control signal being a pulse when a new frame of the LCD begins
	input  iEnd_Frame,		// Control signal being a pulse when a frame of the LCD ends
	input  i_next_active,			// SDRAM read control signal
    output logic [31:0] o_pixel_data,
    // MMU
    input logic [31:0] i_readdata,
    output logic o_load_new,
    output logic o_read_enable,
    output logic [23:0] o_base_address,
    output logic [23:0] o_max_address
);
	//Parameters for the SDRAM Controller
	//- RANGE_ADDR_IMG is equal to 480x800 times 2 (again for 32-bit vs 16-bit bus).
	parameter	RANGE_ADDR_IMG	= 23'd768000;
	
	logic   [4:0]   current_img;
	 
    // Image selector
	always_ff @(posedge iCLK_50, posedge iRST) 
    begin
		if (iRST) 
        begin
			current_img <= 5'b0;
		end 
        else
        begin
            if (iGest_E)
            begin
                // Wrap around between slides
                if (current_img == 5'b0)
                    current_img <= iImg_Tot[4:0] - 5'b1;
                else
                    current_img <= current_img - 5'b1;
            end
            else if (iGest_W)
            begin
                if (current_img == (iImg_Tot[4:0] - 5'b1))
                    current_img <= 5'b0;
                else
                    current_img <= current_img + 5'b1;		
            end
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
			o_base_address <= 24'b0;
			o_max_address <= RANGE_ADDR_IMG;
			o_load_new 		<= 1'b0;
		end else begin
			if (iEnd_Frame) begin
				o_base_address <= current_img*RANGE_ADDR_IMG;
				o_max_address <= current_img*RANGE_ADDR_IMG + RANGE_ADDR_IMG;
			end else begin
                // FIXME: useless I suppose?
                o_base_address <= o_base_address;
                o_max_address <= o_max_address;
				//base_read_addr <= base_read_addr;
				//max_read_addr  <= max_read_addr;
			end
			o_load_new <= iNew_Frame;
		end
	end
    
    assign o_read_enable = i_next_active;
    assign o_pixel_data = image_loaded ? i_readdata : 32'h001080D0;
endmodule 
