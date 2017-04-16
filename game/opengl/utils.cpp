#include "utils.hpp"

#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

void export_bmp_py(unsigned int* img, size_t img_len) {
    unsigned char *buf = (unsigned char *) img;
    for (int i = 0; i < 800*480; i++) {
        unsigned char r = buf[4*i+2];
        unsigned char g = buf[4*i+1];
        unsigned char b = buf[4*i];
        buf[3*i] = r;
        buf[3*i+1] = g;
        buf[3*i+2] = b;
    }
    export_bmp((char *)"img.bmp", 800, 480, (unsigned char *) img);
}
void export_bmp(char *fname, int width, int height, unsigned char* img)
{
    FILE *f;
    int filesize = 54 + 3*width*height;
    unsigned char bmpfileheader[14] = {'B','M', 0,0,0,0, 0,0, 0,0, 54,0,0,0};
    unsigned char bmpinfoheader[40] = {40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0, 24,0};
    unsigned char bmppad[3] = {0,0,0};

    bmpfileheader[ 2] = (unsigned char)(filesize    );
    bmpfileheader[ 3] = (unsigned char)(filesize>> 8);
    bmpfileheader[ 4] = (unsigned char)(filesize>>16);
    bmpfileheader[ 5] = (unsigned char)(filesize>>24);

    bmpinfoheader[ 4] = (unsigned char)(       width    );
    bmpinfoheader[ 5] = (unsigned char)(       width>> 8);
    bmpinfoheader[ 6] = (unsigned char)(       width>>16);
    bmpinfoheader[ 7] = (unsigned char)(       width>>24);
    bmpinfoheader[ 8] = (unsigned char)(       height    );
    bmpinfoheader[ 9] = (unsigned char)(       height>> 8);
    bmpinfoheader[10] = (unsigned char)(       height>>16);
    bmpinfoheader[11] = (unsigned char)(       height>>24);

    int i;
    for (i=0; i<width*height; i++) {
        char r = img[3*i+2];
        char b = img[3*i+0];
        img[3*i+2] = b;
        img[3*i+0] = r;
    }

    f = fopen(fname,"wb");
    fwrite(bmpfileheader,1,14,f);
    fwrite(bmpinfoheader,1,40,f);
    for(i=0; i<height; i++)
    {
        fwrite(img+(width*(height-i-1)*3),3,width,f);
        fwrite(bmppad,1,(4-(width*3)%4)%4,f);
    }
    fclose(f);

}

void export_raw(char *fname, int width, int height, unsigned char* img)
{
    FILE *f;
    f = fopen(fname,"wb");
    fwrite(img, 4, width*height, f);
    fclose(f);

}

unsigned int uint_min(unsigned int a, unsigned int b)
{
    return a < b ? a: b;
}

void cat_bits(unsigned int **buf, int *fill, unsigned int val, int n_bits)
{
    **buf |= val << *fill;
    int new_fill = *fill + n_bits;
    if (new_fill >= 32) {
        *buf += 1;
        new_fill -= 32;
        if (*fill != 0) {
            **buf |= val >> (32-*fill);
        }
    }
    *fill = new_fill;
}
