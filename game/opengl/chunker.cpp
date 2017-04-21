#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

#include "chunker.hpp"
#include "utils.hpp"

int next_chunk(
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

chunker_iter new_chunk_iter(
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

