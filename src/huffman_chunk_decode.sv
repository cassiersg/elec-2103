module huffman_chunk_decoder #(parameter ADDR_WIDTH=16) (
    input logic clk,
    input logic pixel_read_next,
    input logic pixel_reset,
    input logic [31:0] RAM_readdata,
    output logic [31:0] color,
    output logic [ADDR_WIDTH-1:0] RAM_address
);
logic [31:0] buffer_lsb, buffer_msb, buffer_lsb_next;
logic [63:0] wide_buffer;
logic [ADDR_WIDTH-1:0] address, address_next_gated;
logic [31:0] color_next;
logic [15:0] length, length_next, length_counter; // enough for max run length of 65535
logic [5:0] offset, offset_next, offset_tot; // must hold up to 32 (63 for offset_tot)
logic [5:0] len_code_color, len_code_length; // must hold up to 32
logic [31:0] code_color, code_length; // max code size: 32 bits
logic read_next_chunk, increment_address, reset_load_buffer_lsb;

assign buffer_msb = {RAM_readdata[7:0], RAM_readdata[15:8], RAM_readdata[23:16], RAM_readdata[31:24]};
assign RAM_address = pixel_reset ? 0 : address_next_gated;

assign wide_buffer = {buffer_msb, buffer_lsb};
assign code_color = (wide_buffer >> offset);
// Purely combinational code
huffman_color_decoder color_decoder(
    .code(code_color), // input
    .out(color_next), // output
    .code_len(len_code_color) // output
);
assign code_length = (wide_buffer >> (offset + len_code_color));
// Purely combinational code
huffman_length_decoder length_decoder(
    .code(code_length), // input
    .out(length_next), // output
    .code_len(len_code_length) // output
);

always_comb
if (pixel_read_next && read_next_chunk && increment_address)
    address_next_gated = address + 1;
else
    address_next_gated = address;

assign offset_tot = offset + len_code_color + len_code_length;
assign increment_address = offset_tot >= 32;
assign offset_next = increment_address ? offset_tot - 6'd32 : offset_tot;
assign buffer_lsb_next = increment_address ? buffer_msb : buffer_lsb;

assign read_next_chunk = (length_counter == 1);

always_ff @(posedge clk)
begin
    if (pixel_reset) begin
        reset_load_buffer_lsb <= 1; // we need to initialize buffer_lsb. Due to the 1 cycle delay of the RAM, we need this trick.
    end else if (reset_load_buffer_lsb) begin
        length_counter <= 1; // so that we will activate the first pixel at first toggle of pixel_read_next
        reset_load_buffer_lsb <= 0;
        offset <= 0;
        buffer_lsb <= buffer_msb; // buffer_msb was loaded from RAM[0] at previous cycle
        address <= 1; // initialize correctly buffer_msb
    end else if (pixel_read_next) begin
        if (read_next_chunk) begin
            color <= color_next;
            length_counter <= length_next;
            address <= address_next_gated;
            buffer_lsb <= buffer_lsb_next;
            offset <= offset_next;
        end else begin
            length_counter <= length_counter - 16'b1;
        end
    end
end

endmodule

module huffman_color_decoder(
    input logic [31:0] code,
    output logic [31:0] out,
    output logic [7:0] code_len
);
logic [31:0] decoded;
assign out = decoded;

always_comb
`include "huffman_decode_colors.sv"

endmodule

module huffman_length_decoder(
    input logic [31:0] code,
    output logic [15:0] out,
    output logic [7:0] code_len
);
logic [31:0] decoded;
assign out = decoded[15:0];

always_comb
`include "huffman_decode_lengths.sv"

endmodule
