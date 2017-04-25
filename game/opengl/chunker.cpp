#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>

#include "chunker.hpp"
#include "utils.hpp"

static void inc_rem_cst(chunker_iter *iter);

const size_t chunk_sizes[] = {2048, 512, 256, 128, 64, 32, 16};
const size_t n_sizes = sizeof(chunk_sizes)/sizeof(chunk_sizes[0]);
const size_t min_all_chunk_sizes = chunk_sizes[n_sizes-1];


int next_chunk(
        chunker_iter *iter, unsigned int *chunk_value, unsigned int *chunk_size)
{
    if (iter->idx >= iter->input_len) {
        return ITERATION_FINISHED;
    }
    unsigned int chunk_val = iter->input[iter->idx];
    *chunk_value = chunk_val;
    if (iter->rem_cst == 0) {
        inc_rem_cst(iter);
    }
    size_t chunk_len = 0;
    if (iter->rem_cst <= min_all_chunk_sizes) {
        chunk_len = iter->rem_cst;
    } else {
        for (int i=0; i < n_sizes; i++) {
            if (iter->rem_cst >= chunk_sizes[i]) {
                chunk_len = chunk_sizes[i];
                break;
            }
        }
        assert(chunk_len != 0);
    }
    assert(chunk_len <= 4096);
    *chunk_size = (unsigned int) chunk_len;
    iter->idx += chunk_len;
    iter->rem_cst -= chunk_len;
    return ITERATION_CONTINUE;
}


static void inc_rem_cst(chunker_iter *iter)
{
    unsigned int chunk_val = iter->input[iter->idx];
    size_t max_chunk_len = iter->input_len - iter->idx;
    size_t chunk_len = 1;
    while (iter->input[iter->idx + chunk_len] == chunk_val &&
            chunk_len < max_chunk_len) {
        chunk_len++;
    }
    iter->rem_cst = chunk_len;
}

chunker_iter new_chunk_iter(
        unsigned int *input, size_t input_len)
{
    chunker_iter res = {
        .input = input,
        .input_len = input_len,
        .idx = 0,
        .rem_cst = 0,
    };
    return res;
}

unsigned int make_chunks(
        unsigned int *input, size_t input_len, unsigned int *output,
        size_t output_len)
{
    chunker_iter iter = new_chunk_iter(input, input_len);
    size_t i;
    for (i = 0; i < output_len-1; i+=2) {
        if (next_chunk(&iter, output+i, output+i+1) == ITERATION_FINISHED) {
            break;
        }
    }
    return i;
}

