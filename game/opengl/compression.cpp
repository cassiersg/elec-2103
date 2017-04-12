#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

#include "compression.hpp"
#include "utils.hpp"

#define ITERATION_FINISHED 0
#define ITERATION_CONTINUE 1

typedef struct {
    unsigned int *input;
    size_t input_len;
    size_t max_chunk_size;
    size_t idx;
} chunker_iter;

static chunker_iter new_chunk_iter(
        unsigned int *input, size_t input_len, size_t max_chunk_size);
static int next_chunk(
        chunker_iter *iter, unsigned int *chunk_value, size_t *chunk_size);

static int huffman_color_encode_one(
        unsigned int *color);
static void huffman_color_decode_one(
        unsigned int code, unsigned int *res, int *len);
static int huffman_encode_color_buf(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len);
static void huffman_decode_color_buf(
        unsigned int *input, int input_code_nb,
        unsigned int *output);

static int next_chunk(
        chunker_iter *iter, unsigned int *chunk_value, unsigned int *chunk_size)
{
    if (iter->idx >= iter->input_len) {
        return ITERATION_FINISHED;
    }
    unsigned int chunk_val = iter->input[iter->idx];
    size_t max_chunk_len =
        uint_min(iter->max_chunk_size, iter->input_len - iter->idx);
    size_t chunk_len = 1;
    while (iter->input[iter->idx + chunk_len] == chunk_val &&
            chunk_len < max_chunk_len) {
        chunk_len++;
    }
    iter->idx += chunk_len;
    *chunk_value = chunk_val;
    *chunk_size = (unsigned int) chunk_len;
    return ITERATION_CONTINUE;
}

static chunker_iter new_chunk_iter(
        unsigned int *input, size_t input_len, size_t max_chunk_size)
{
    chunker_iter res = {
        .input = input,
        .input_len = input_len,
        .max_chunk_size = max_chunk_size,
        .idx = 0,
    };
    return res;
}

unsigned int make_chunks(
        unsigned int *input, size_t input_len, unsigned int *output,
        size_t output_len, unsigned int max_chunk_size)
{
    chunker_iter iter = new_chunk_iter(input, input_len, max_chunk_size);
    size_t i;
    for (i = 0; i < output_len-1; i+=2) {
        if (next_chunk(&iter, output+i, output+i+1) == ITERATION_FINISHED) {
            break;
        }
    }
    return i;
}


int chunk_compress_huffman(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len,
        unsigned int max_chunk_size)
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
        //n_bits = huffman_code_len(&chunk_len);
        //cat_bits(&output, &fill, chunk_len, n_bits);
        if (output >= output_end) {
            printf("compressiong, too small output\n");
            assert(0);
        }
        n_chunks++;
    }
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
        int code = (*input >> offset);
        if (offset != 0) {
            code |= (*(input+1) << (32-offset));
        }
        int len;
        huffman_color_decode_one(code, output+i, &len);
        offset += len;
        if (offset >= 32) {
            offset -= 32;
            input += 1;
        }
    }
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

