`timescale 1ns/100ps 	// time unit / compiler time precision

module display_tb();

// Set up variables 
logic clk;	 
logic rst_n;

logic next_display_active, new_frame, end_frame, hsync, vsync;

logic [7:0] lcd_r, lcd_g, lcd_b;
logic [10:0] next2x;
logic [9:0] next2y;
logic [15:0] address;
logic [31:0] color, readdata;
logic [31:0] pix_counter;
logic [31:0] RAM [20000:0];
logic [31:0] expected_output [800*480-1:0];
logic ok;
initial
begin
    $readmemh("ram_compressed.hex", RAM);
    $readmemh("ram_uncompressed.hex", expected_output);
end
always_ff @(posedge clk)
    readdata <= RAM[address];
assign ok = expected_output[pix_counter-1] == color;

mtl_display dut(
    .iCLK(clk),
    .iRST_n(rst_n),
    .iREAD_DATA(32'b0),
    .next_display_active(next_display_active),
    .oNew_Frame(new_frame),
    .oEnd_Frame(end_frame),
    .oHD(hsync),
    .oVD(vsync),
    .oLCD_R(lcd_r),
    .oLCD_G(lcd_g),
    .oLCD_B(lcd_b),
    .o_next2_x(next2x),
    .o_next2_y(next2y)
);
huffman_chunk_decoder dut2(
    .clk(clk),
    .pixel_read_next(next_display_active),
    .pixel_reset(end_frame | ~rst_n),
    .RAM_readdata(readdata),
    .color(color),
    .RAM_address(address)
);

// clk generator, used to decide when we have to apply a new test
always
begin
	#1 clk = 1;
	#1 clk = 0;
end

// At start of test, pulse reset
initial
begin
    rst_n = 0;
    #5 rst_n = 1;
end

always_ff @(posedge clk)
begin
    if (~rst_n || new_frame)
        pix_counter <= 32'b0;
    else if (next_display_active)
        pix_counter <= pix_counter + 1;
end
 
endmodule
