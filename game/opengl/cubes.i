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
        int player_id,
        int round_gauge,
        unsigned int wall_color);

void cubes_init();
void cubes_exit();

%pybuffer_mutable_binary(unsigned char *str, int str_size);
void cubes_image_export(unsigned char *str, int str_size);

const int width;
const int height;

const int m;
const int n;
