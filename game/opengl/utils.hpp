#ifndef _H_UTILS_H_373267
#define _H_UTILS_H_373267

#include <stdlib.h>

void export_bmp_py(unsigned int* img, size_t img_len, char *fname);
void export_bmp(char *fname, int width, int height, unsigned char* img);
void export_raw(char *fname, int width, int height, unsigned char* img);
unsigned int uint_min(unsigned int a, unsigned int b);
unsigned int uint_max(unsigned int a, unsigned int b);
void cat_bits(unsigned int **buf, int *fill, unsigned int val, int n_bits);

#endif
