%module chunker

%include <pybuffer.i>

%{
#define SWIG_FILE_WITH_INIT
#include "chunker.hpp"
%}

%pybuffer_mutable_binary(unsigned int *in_buf, size_t in_len);
%pybuffer_mutable_binary(unsigned int *out_buf, size_t out_len);

unsigned int make_chunks(
        unsigned int *in_buf, size_t in_len,
        unsigned int *out_buf, size_t out_len);

