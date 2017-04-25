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

static void test_compression_current_image(void)
{
    unsigned char *pixels = (unsigned char *) malloc(4*width*height);
    assert(pixels != NULL);
    cubes_image_export(pixels, 4*width*height);
    export_bmp_py((unsigned int *)pixels, 0, (char *)"main_img.bmp");
    /*
    unsigned int *compressed = (unsigned int*) malloc(4*width*height);
    assert(compressed != NULL);
    size_t output_size = width*height;
    int n_chunks = chunk_compress_huffman((unsigned int *) pixels, width*height,
            compressed, output_size,
            (unsigned int *) &output_size);
    printf("compressed size: %u bytes\n", 4*output_size);
    unsigned int *pixels2 = (unsigned int*) malloc(4*width*height);
    assert(pixels2 != NULL);
    assert(chunk_decompress_huffman(compressed, 0, pixels2, width*height, n_chunks) == width*height);
    for (int i=0; i< width*height; i++) {
        assert(pixels2[i] == ((unsigned int *) pixels)[i]);
    }
    */
}

static const int round_gauge = 20000;
int main() {
    test_huffman_color();
    printf("huffman color ok\n");
    test_compression_current_image();


    return 0;
}
