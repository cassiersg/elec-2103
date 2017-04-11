#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "gl_utils.hpp"
#include "utils.hpp"
#include "cubes.hpp"

static const int m = 15;
static const int n = 7;
static const unsigned char example_grid[n][m] = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3},
    {3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3},
    {3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
};

static const int round_gauge = 20000;
int main() {
    cubes_init();
    draw_cubes((unsigned char *) example_grid, m*n, n, m, 0, 1, 14, 1, 1, round_gauge);

    unsigned char *buf = (unsigned char *) malloc(3*width*height);
    glbuf2rgb(buf, width, height);
    export_bmp((char *)"img.bmp", width, height, buf);
    free(buf);

    return 0;
}
