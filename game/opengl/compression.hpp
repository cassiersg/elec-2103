#ifndef __H_COMPRESSION_H_
#define __H_COMPRESSION_H_

unsigned int make_chunks(
        unsigned int *input, size_t input_len, unsigned int *output,
        size_t output_len, unsigned int max_chunk_size);

int chunk_compress_huffman(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len,
        unsigned int max_chunk_size,
        unsigned int *output_used);

size_t chunk_decompress_huffman(
        unsigned int *input, size_t input_len,
        unsigned int *output, size_t output_len,
        int n_chunks);

void test_huffman_color(void); // -> main
#endif

