%module cubes

%include <pybuffer.i>

%{
#define SWIG_FILE_WITH_INIT
#include "cubes.hpp"
%}

void draw_cubes();

void cubes_init();
void cubes_exit();

%pybuffer_mutable_binary(unsigned char *str, int buf_size);
void cubes_image_export(unsigned char *str, int buf_size);

const int width;
const int height;
