%module compression

%include <pybuffer.i>

%{
#define SWIG_FILE_WITH_INIT
#include "compression.hpp"
%}

%pybuffer_mutable_binary(unsigned int *in_buf, size_t in_len);
%pybuffer_mutable_binary(unsigned int *out_buf, size_t out_len);

int chunk_compress_huffman(
        unsigned int *in_buf, size_t in_len,
        unsigned int *out_buf, size_t out_len,
        unsigned int max_chunk_size,
        unsigned int *OUTPUT);

size_t chunk_decompress_huffman(
        unsigned int *in_buf, size_t in_len,
        unsigned int *out_buf, size_t out_len,
        int n_chunks);
