%module image_manip

%include <pybuffer.i>

%{
#define SWIG_FILE_WITH_INIT
#include "image_manip.hpp"
#include "utils.hpp"
%}

%pybuffer_mutable_binary(unsigned char *img, size_t img_size);
%pybuffer_binary(unsigned char *mask, size_t mask_size);


void blit_image(
        unsigned char *img, size_t img_size,
        unsigned int img_width, unsigned int img_height,
        unsigned char *mask, size_t mask_size,
        unsigned int mask_width, unsigned int mask_height,
        unsigned int x_off, unsigned int y_off,
        unsigned int color);

void draw_rect(
        unsigned char *img, size_t img_size,
        unsigned int img_width, unsigned int img_height,
        unsigned int x_off, unsigned int y_off,
        unsigned int x_size, unsigned int y_size,
        unsigned int color);

%pybuffer_mutable_binary(unsigned int *in_buf, size_t in_len);
%pybuffer_string(char *fname)
void export_bmp_py(unsigned int* in_buf, size_t in_len, char *fname);
