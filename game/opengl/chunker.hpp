#ifndef __H_CHUNKER_H_
#define __H_CHUNKER_H_

#define ITERATION_FINISHED 0
#define ITERATION_CONTINUE 1

typedef struct {
    unsigned int *input;
    size_t input_len;
    size_t idx;
    size_t rem_cst;
} chunker_iter;

chunker_iter new_chunk_iter(
        unsigned int *input, size_t input_len);
int next_chunk(
        chunker_iter *iter, unsigned int *chunk_value, unsigned int *chunk_size);

unsigned int make_chunks(
        unsigned int *input, size_t input_len, unsigned int *output,
        size_t output_len);

#endif
