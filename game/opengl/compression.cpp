#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

#include "compression.hpp"
#include "chunker.hpp"
#include "utils.hpp"

static int huffman_color_encode_one(
        unsigned int *color);
static void huffman_color_decode_one(
        unsigned int code, unsigned int *res, int *len);
static int huffman_length_encode_one(
        unsigned int *length);
static void huffman_length_decode_one(
        unsigned int code, unsigned int *res, int *len);
static unsigned int huffman_decode_color_block(
        unsigned int **input,
        int *offset);
static unsigned int huffman_decode_length_block(
        unsigned int **input,
        int *offset);

static int huffman_encode_color_buf(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len);
static void huffman_decode_color_buf(
        unsigned int *input, int input_code_nb,
        unsigned int *output);

int chunk_compress_huffman(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len,
        unsigned int max_chunk_size,
        unsigned int *output_used)
{
    chunker_iter iter = new_chunk_iter(input, input_len, max_chunk_size);
    unsigned int *output_end = output + output_len;
    int fill = 0;
    unsigned int color, chunk_len;
    int n_chunks = 0;
    while (next_chunk(&iter, &color, &chunk_len) == ITERATION_CONTINUE)
    {
        int n_bits = huffman_color_encode_one(&color);
        cat_bits(&output, &fill, color, n_bits);
        n_bits = huffman_length_encode_one(&chunk_len);
        cat_bits(&output, &fill, chunk_len, n_bits);
        if (output >= output_end) {
            printf("compressiong, too small output\n");
            assert(0);
        }
        n_chunks++;
    }
    if (fill != 0) {
        output++; // paritally used word, counted
    }
    *output_used = output_len - (output_end - output); // upper bound on len used
    return n_chunks;
}

static int huffman_encode_color_buf(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len)
{
    unsigned int *output_end = output + output_len;
    int fill = 0;
    unsigned int color;
    int n_chunks = 0;
    for (int i=0; i < input_len; i++)
    {
        color = input[i];
        int n_bits = huffman_color_encode_one(&color);
        cat_bits(&output, &fill, color, n_bits);
        if (output >= output_end) {
            printf("compressiong, too small output\n");
            assert(0);
        }
        n_chunks++;
    }
    return n_chunks;
}

static void huffman_decode_color_buf(
        unsigned int *input, int input_code_nb,
        unsigned int *output) 
{
    int offset = 0;
    for (int i=0; i < input_code_nb; i++) {
        output[i] = huffman_decode_color_block(&input, &offset);
    }
}

size_t chunk_decompress_huffman(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len,
        int n_chunks)
{
    int offset = 0;
    size_t output_idx = 0;
    for (int i=0; i < n_chunks; i++) {
        unsigned int color = huffman_decode_color_block(&input, &offset);
        unsigned int length = huffman_decode_length_block(&input, &offset);
        for (int j=0; j < length; j++) {
            assert(output_idx < output_len);
            output[output_idx] = color;
            output_idx ++;
        }
    }
    return output_idx;
}

static unsigned int huffman_decode_color_block(
        unsigned int **input,
        int *offset)
{
    int code = (**input >> *offset);
    if (*offset != 0) {
        code |= (*(*input+1) << (32-*offset));
    }
    int len;
    unsigned int color;
    huffman_color_decode_one(code, &color, &len);
    *offset += len;
    if (*offset >= 32) {
        *offset -= 32;
        *input += 1;
    }
    return color;
}

static unsigned int huffman_decode_length_block(
        unsigned int **input,
        int *offset)
{
    int code = (**input >> *offset);
    if (*offset != 0) {
        code |= (*(*input+1) << (32-*offset));
    }
    int len;
    unsigned int color;
    huffman_length_decode_one(code, &color, &len);
    *offset += len;
    if (*offset >= 32) {
        *offset -= 32;
        *input += 1;
    }
    return color;
}

static int huffman_color_encode_one(unsigned int *color)
{
    int n_bits;
    unsigned int code;
    switch (*color) {
// sets code and n_bits
#include "huffman_encode_colors.cpp"
        default:
            printf("invalid color: %x\n", *color);
            assert(0);
    }
    *color = code;
    return n_bits;

}

static void huffman_color_decode_one(unsigned int code, unsigned int *res, int *len)
{
    unsigned int decoded;
    int code_len;
#include "huffman_decode_colors.cpp"
    *res = decoded;
    *len = code_len;
}

static int huffman_length_encode_one(unsigned int *length)
{
    int n_bits;
    unsigned int code;
    switch (*length) {
// sets code and n_bits
#include "huffman_encode_lengths.cpp"
        default:
            printf("invalid length: %x\n", *length);
            assert(0);
    }
    *length = code;
    return n_bits;

}

static void huffman_length_decode_one(unsigned int code, unsigned int *res, int *len)
{
    unsigned int decoded;
    int code_len;
#include "huffman_decode_lengths.cpp"
    *res = decoded;
    *len = code_len;
}

void test_huffman_color(void)
{
    unsigned int colors[] = {
        4281551948u, 4281551948u, 4281551948u, 4281551948u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4285887861u, 4285887861u, 4281551948u, 4282071867u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4285887861u, 4285887861u, 4281551948u, 4282071867u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4285887861u, 4285887861u, 4281551948u, 4282071867u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4281551948u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4293585642u, 4285887861u, 4285887861u, 4281551948u
    };
    unsigned int *buf = (unsigned int *) malloc(sizeof(colors));
    unsigned int *res = (unsigned int *) malloc(sizeof(colors));
    huffman_encode_color_buf(colors, 100, buf, 100);
    huffman_decode_color_buf(buf, 100, res);
    int fail = 0;
    for (int i=0; i<100; i++) {
        if (res[i] != colors[i]) {
            printf("i : %i, res: %u, colors: %u\n", i, res[i], colors[i]);
            fail = 1;
        }
    }
    if (fail) assert(0);
}

