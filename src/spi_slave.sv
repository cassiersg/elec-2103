
module spi_mm(
    input logic clk,
    input logic reset,
    // Avalon MM interface
    input logic avs_s0_write,
    input logic [7:0] avs_s0_address,
    input logic [31:0] avs_s0_writedata,
    output logic [31:0] avs_s0_readdata,
    // SPI interface
    input logic spi_clk,
    input logic spi_cs,
    input logic spi_mosi,
    output logic spi_miso,
    // MTL interface
    output logic [23:0] oPix_Data, // Pixel's data from R-Pi (24-bit RGB)
    output logic  [7:0] oImg_Tot, // Total number of images transferred from Rasp-Pi

    // Short pulse that is raised each time a whole pixel has been
    // received by the spi slave interface. Trigger enables writing 
    // the pixel to the SDRAM.
    output logic oTrigger
    
);

spi_slave impl(
    .iCLK(clk),
    .iRST(reset),
    .iSPI_CLK(spi_clk),
    .iSPI_MOSI(spi_mosi),
    .iSPI_CS(spi_cs),
    .oSPI_MISO(spi_miso),
    .iData_WE(avs_s0_write),
    .iData_Addr(avs_s0_address),
    .iData_Write(avs_s0_writedata),
    .oData_Read(avs_s0_readdata),
    .oPix_Data(oPix_Data),
    .oImg_Tot(oImg_Tot),
    .oTrigger(oTrigger)
);

endmodule

module spi_slave(
    input  logic iCLK, // System clock
    input  logic iRST, // System sync reset
    // SPI
    input  logic iSPI_CLK, // SPI clock
    input  logic iSPI_CS, // SPI chip select
    input  logic iSPI_MOSI, // SPI MOSI (from Rasp-Pi)
    output logic oSPI_MISO, // SPI MISO (to Rasp-Pi)
    // Internal registers R/W	
    input  logic  iData_WE, // Write enable for SPI internal registers (not used here)
    input  logic [31:0] iData_Addr, // Write address for SPI internal registers (not used here)
    input  logic [31:0] iData_Write, // Write data for SPI internal registers (not used here)
    output logic [31:0] oData_Read, // Read data from SPI internal registers (not used here)
    // MTL
    output logic [23:0] oPix_Data, // Pixel's data from R-Pi (24-bit RGB)
    output logic  [7:0] oImg_Tot, // Total number of images transferred from Rasp-Pi

    // Short pulse that is raised each time a whole pixel has been
    // received by the spi slave interface. Trigger enables writing 
    // the pixel to the SDRAM.
    output logic oTrigger
);

logic [39:0] SPI_reg;

//---Input Registers -(from PI to ARM) ------------------------


logic [31:0] mosiRAM[15:0];
logic mosiRAM_we;

logic [7:0] img_tot;
logic [23:0] pix_data;	 

assign oData_Read = mosiRAM[iData_Addr[3:0]]; 

always_ff @(posedge iCLK) begin
    if(iRST)
    begin 
        pix_data <= 24'd0;
        img_tot  <= 8'd0;
    end	
    else if (mosiRAM_we)
    begin
        case (SPI_reg[36:32])
            5'd16: img_tot <= SPI_reg[7:0];
            5'd17: pix_data <= SPI_reg[23:0];
            default: mosiRAM[SPI_reg[35:32]] <= SPI_reg[31:0]; 
        endcase
    end
end

assign oImg_Tot = img_tot;
assign oPix_Data = pix_data;

//--- Output Registers - (from ARM to PI)----------------------

logic [31:0] misoRAM[15:0];
logic [31:0] misoRAM_read;

assign misoRAM_read = misoRAM[SPI_reg[3:0]];

always_ff @(posedge iCLK) begin
    if (iData_WE) misoRAM[iData_Addr[5:2]] <= iData_Write;
end

//---SPI Sysnchronization -------------------------------------

logic SPI_CLK_sync;
logic SPI_CS_sync;

always_ff @(posedge iCLK) begin
    SPI_CLK_sync <= iSPI_CLK;
    SPI_CS_sync <= iSPI_CS;
end

//--- SPI FSM -------------------------------------------------

typedef enum logic [1:0] {S0,S1,S2,S3} statetype;
statetype state, nextstate;

logic [5:0] SPI_cnt;
logic SPI_cnt_reset, SPI_cnt_inc;
logic SPI_reg_reset, SPI_reg_shift, SPI_reg_load;	
logic MISO_we, MISO_reset;

// State Register & Bit counter & SPI Register & MISO

always_ff @(posedge iCLK)
begin
    if (SPI_CS_sync)
        state <= S0;
    else
        state <= nextstate;

    if (SPI_cnt_reset)
        SPI_cnt <= 6'b0;
    else if (SPI_cnt_inc)
        SPI_cnt <= SPI_cnt + 6'b1;

    if (SPI_reg_reset)
        SPI_reg <= 40'b0;
    else if (SPI_reg_shift)
        SPI_reg <= {SPI_reg[38:0], iSPI_MOSI};
    else if (SPI_reg_load)
        SPI_reg <= {misoRAM_read, SPI_reg[7:0]};

    if (MISO_reset)
        oSPI_MISO <= 0;
    else if (SPI_reg_load)
        oSPI_MISO <= misoRAM_read[31];
    else if (MISO_we)
        oSPI_MISO <= SPI_reg[39];
end

// Next State Logic
always_comb
begin
    // Default value
    nextstate = state;
    SPI_cnt_reset = 0; SPI_cnt_inc = 0;
    SPI_reg_reset = 0; SPI_reg_shift = 0; SPI_reg_load = 0;
    MISO_we = 0; MISO_reset = 0;
    mosiRAM_we = 0;
    oTrigger = 0;

    case (state)
        S0: if (~SPI_CS_sync) // negedge of SPI_CS
        begin
            SPI_cnt_reset = 1;
            SPI_reg_reset = 1;
            MISO_reset = 1;
            oTrigger = 0;
            nextstate = S1;
        end
        S1: if (SPI_CLK_sync) // posedge of SPI_CLK
        begin
            SPI_reg_shift = 1;
            SPI_cnt_inc   = 1;
            nextstate = S2;
        end
        S2 : if (~SPI_CLK_sync) // negedge of SPI_CLK
        begin
            MISO_we = 1;
            if (SPI_cnt == 8) SPI_reg_load = 1;
            if (SPI_cnt == 40) begin
                if (SPI_reg[39] == 1) begin 
                    mosiRAM_we = 1; 
                    if((SPI_reg[36:32]==5'd17))
                        oTrigger = 1;
                end
                nextstate = S3;
            end
            else nextstate = S1;
        end
        S3 : if (SPI_CS_sync) // posedge of SPI_CS
        begin
            nextstate = S0;
        end
    endcase
end

endmodule // spi_slave
