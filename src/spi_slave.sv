//-------------------------------------------------------------
//
// SPI Module
// 
// TODO
// fix interblock delay (currently 3)
// enabled/disabled RAM : enable on write, disable on read, test if enabled


// All addresses are in words (32 bytes).

module spi_slave(
	input  logic 			SPI_CLK,
	input  logic			SPI_CS,
	input  logic 			SPI_MOSI,
	output logic 			SPI_MISO,
	output logic 			Data_WE,
	output logic[27:0] 	Data_Addr,
	output logic[31:0] 	Data_Write,
	input  logic[31:0] 	Data_Read,
	output logic mem_read,
	input  logic Clk,
	input logic reset
);

logic end_block, update_addr, update_burst_size;
logic reset_addr_offset, inc_addr_offset;
logic [27:0] burst_size;
logic [27:0] addr_offset;
logic [27:0] base_addr;
logic spi_enabled;
logic do_read;

assign mem_read = do_read;
assign Data_Addr = base_addr + addr_offset;

typedef enum logic [1:0] {Command, RAM_writing, RAM_reading} ReceiveState;
ReceiveState state, nextstate;

always_ff @(posedge Clk)
begin
	state <= spi_enabled ? nextstate : Command;
	if (update_addr) base_addr <= Data_Write[27:0];
	if (update_burst_size) burst_size <= Data_Write[27:0];
	if (reset_addr_offset) addr_offset <= 28'b0;
	if (inc_addr_offset) addr_offset <= addr_offset + 28'h1;
end

always_comb
begin
	nextstate = state;
	Data_WE = 1'b0;
	update_addr = 1'b0;
	update_burst_size = 0;
	reset_addr_offset = 0;
	inc_addr_offset = 0;
	do_read = 0;
	case (state)
		Command:
		if (end_block)
		begin
			casez (Data_Write[31:28])
				//8'h0: nextstate = Command; // reset
				8'h1:
				begin
					nextstate = RAM_writing;
					update_burst_size = 1;
				end
				8'h2:
				begin
					nextstate = RAM_reading;
					update_burst_size = 1;
					do_read = 1;
					inc_addr_offset = 1;
				end
				8'h3: // set address
				begin
					nextstate = Command;
					update_addr = 1;
				end
				default: nextstate = Command;
			endcase
		end
		RAM_writing:
		if (end_block)
		begin
			if (addr_offset == burst_size - 1)
			begin
				nextstate = Command;
				reset_addr_offset = 1;
			end
			else inc_addr_offset = 1;
			Data_WE = end_block;
		end
		RAM_reading:
		if (end_block)
		begin
			if (addr_offset == burst_size)
			begin
				nextstate = Command;
				reset_addr_offset = 1;
			end
			else
			begin
				inc_addr_offset = 1;
				do_read = 1;
			end
		end
	endcase
end

spi_slave_sub spi_slave_sub_inst (
	.SPI_CLK(SPI_CLK),
	.SPI_CS(SPI_CS),
	.SPI_MOSI(SPI_MOSI),
	.SPI_MISO(SPI_MISO),
	.Data_Write(Data_Write),
	.Data_Read(Data_Read),
	.end_block(end_block),
	.Clk(Clk),
	.spi_enabled(spi_enabled),
	.load_data(do_read)
);

endmodule

module spi_slave_sub(
	input  logic 			SPI_CLK,
	input  logic			SPI_CS,
	input  logic 			SPI_MOSI,
	output logic 			SPI_MISO,
	output logic[31:0] 	Data_Write,
	input  logic[31:0] 	Data_Read,
	output logic end_block,  // triggered once each time a word has been written to/read from SPI
	input  logic			Clk,
	output logic spi_enabled,
	input logic load_data // must be asserted for one clock cycle between end_block signal and the next negedge of SPI_CLK_sync
);

	logic [31:0] SPI_reg;

	assign Data_Write =  {SPI_reg[30:0], SPI_MOSI};
	
//---SPI Sysnchronization -------------------------------------
	logic SPI_CLK_sync;
	logic SPI_CS_sync;
	
	assign spi_enabled = ~SPI_CS_sync;

	always_ff @(posedge Clk) begin
		SPI_CLK_sync <= SPI_CLK;
		SPI_CS_sync  <= SPI_CS;
	end
	
//--- SPI FSM -------------------------------------------------
	typedef enum logic [1:0] {S0,S1,S2,S3} statetype;
	statetype state, nextstate;
	
	logic [5:0] SPI_cnt;
	logic 		SPI_cnt_reset, SPI_cnt_inc;
	logic			SPI_reg_shift;
	logic 		MISO_we;
	
// State Register & Bit counter & SPI Register & MISO	
	always_ff @(posedge Clk) begin
		if (SPI_CS_sync)			state <= S0;
		else 							state <= nextstate;
		
		if (SPI_cnt_reset) 	 	SPI_cnt <= 6'b0;
		else if (SPI_cnt_inc) 	SPI_cnt <= SPI_cnt + 6'b1;
		
		if (load_data)	SPI_reg <= Data_Read;
		else if (SPI_reg_shift)	SPI_reg <= {SPI_reg[30:0], SPI_MOSI};
		
		if (MISO_we)			SPI_MISO <= SPI_reg[31];

	end
	
// Next State Logic
	always_comb begin
		// Default value
		nextstate = state;
		SPI_cnt_reset = 0; SPI_cnt_inc = 0;
		SPI_reg_shift = 0;
		MISO_we = 0;
		end_block = 0;
		
		case (state)
			S0 : if (~SPI_CS_sync) begin 			// negedge of SPI_CS
						SPI_cnt_reset = 1;
						nextstate = S1;
					end	
			S1	: if (SPI_CLK_sync) begin			// posedge of SPI_CLK ->  data is valid
						if (SPI_cnt == 31)
						begin
							end_block = 1;
							SPI_cnt_reset = 1;
						end
						SPI_reg_shift = 1;
						SPI_cnt_inc   = 1; 
						nextstate = S2;
					end
			S2 : if (~SPI_CLK_sync) begin			// negedge of SPI_CLK
						MISO_we = 1;
						nextstate = S1;
					end
			S3 : if (SPI_CS_sync) begin 			// posedge of SPI_CS
						nextstate = S0;
					end
		endcase
	end
	
endmodule
	