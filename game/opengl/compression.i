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
        unsigned int *OUTPUT);

%pybuffer_mutable_binary(unsigned int *in_buf, size_t in_len);
%pybuffer_mutable_binary(unsigned int *out_buf, size_t out_len);
size_t chunk_decompress_huffman(
        unsigned int *in_buf, size_t in_len,
        unsigned int *out_buf, size_t out_len,
        int n_chunks);
%pybuffer_mutable_binary(unsigned int *in_buf, size_t in_len);
