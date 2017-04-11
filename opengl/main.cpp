#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "gl_utils.hpp"
#include "utils.hpp"
#include "cubes.hpp"

int main() {
    cubes_init();
    draw_cubes();

    unsigned char *buf = glbuf2rgb(width, height);
    export_bmp((char *)"img.bmp", width, height, buf);
    free(buf);

    return 0;
}
