%module cubes

%include <pybuffer.i>

%{
#define SWIG_FILE_WITH_INIT
#include "cubes.hpp"
%}

%pybuffer_mutable_binary(unsigned char *grid, int grid_size);
void draw_cubes(
        unsigned char *grid, int grid_size,
        int n, int m,
        int p1x, int p1y, int p2x, int p2y,
        int round_gauge,
        unsigned int wall_color,
        int x_offset,
        int off_x1, int off_y1, float angle1,
        int off_x2, int off_y2, float angle2,
        unsigned int p1_tex_intensity,
        unsigned int p2_tex_intensity,
        bool hide_struct
        );
%pybuffer_mutable_binary(unsigned int *texels1, size_t texels_len1);
%pybuffer_mutable_binary(unsigned int *texels2, size_t texels_len2);
void set_textures(
        unsigned int *texels1,
        size_t texels_len1,
        unsigned int *texels2,
        size_t texels_len2,
        unsigned int width,
        unsigned int height);

void cubes_init();
void cubes_exit();

%pybuffer_mutable_binary(unsigned char *str, int str_size);
void cubes_image_export(unsigned char *str, int str_size);

%pybuffer_mutable_binary(unsigned int *str, int buf_size);
void cubes_image_normalize(unsigned int *str, int buf_size);

const int width;
const int height;

const int m;
const int n;
