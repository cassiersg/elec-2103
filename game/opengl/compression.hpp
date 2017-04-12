#ifndef __H_COMPRESSION_H_
#define __H_COMPRESSION_H_


unsigned int make_chunks(
        unsigned int *input, size_t input_len, unsigned int *output,
        size_t output_len, unsigned int max_chunk_size);

void test_huffman_color(void);
#endif

