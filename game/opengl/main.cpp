#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "gl_utils.hpp"
#include "utils.hpp"
#include "cubes.hpp"
#include "compression.hpp"

static const unsigned char example_grid[n][m] = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3},
    {3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3},
    {3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
};

static void test_compression_current_image(void)
{
    unsigned char *pixels = (unsigned char *) malloc(4*width*height);
    assert(pixels != NULL);
    cubes_image_export(pixels, 4*width*height);
    export_bmp_py((unsigned int *)pixels, 0);
    return;
    unsigned int *compressed = (unsigned int*) malloc(4*width*height);
    assert(compressed != NULL);
    size_t output_size = width*height;
    int n_chunks = chunk_compress_huffman((unsigned int *) pixels, width*height,
            compressed, output_size,
            32,
            (unsigned int *) &output_size);
    printf("compressed size: %u bytes\n", 4*output_size);
    unsigned int *pixels2 = (unsigned int*) malloc(4*width*height);
    assert(pixels2 != NULL);
    assert(chunk_decompress_huffman(compressed, 0, pixels2, width*height, n_chunks) == width*height);
    for (int i=0; i< width*height; i++) {
        assert(pixels2[i] == ((unsigned int *) pixels)[i]);
    }
}

static const int round_gauge = 20000;
int main() {
    test_huffman_color();
    printf("huffman color ok\n");
    cubes_init();
    draw_cubes((unsigned char *) example_grid, m*n, n, m, 0, 1, 14, 1, 1, round_gauge);

    unsigned char *buf = (unsigned char *) malloc(3*width*height);
    glbuf2rgb(buf, width, height);
    export_bmp((char *)"img.bmp", width, height, buf);
    test_compression_current_image();
    printf("compression image test succeded\n");
    free(buf);

    return 0;
}
