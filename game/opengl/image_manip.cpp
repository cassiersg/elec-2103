#include <stdlib.h>

#include "utils.hpp"

void blit_image(
        unsigned char *img, size_t img_size,
        unsigned int img_width, unsigned int img_height,
        unsigned char *mask, size_t mask_size,
        unsigned int mask_width, unsigned int mask_height,
        unsigned int x_off, unsigned int y_off,
        unsigned int color)
{
    unsigned int *image = (unsigned int *) img;
    unsigned int eff_width = uint_min(mask_width, img_width - x_off);
    unsigned int eff_height = uint_min(mask_height, img_height - y_off);
    for (int i=0; i < eff_height; i++) {
        for (int j=0; j < eff_width; j++) {
            if (mask[i*mask_width+j]) {
                image[(i+y_off)*img_width + j + y_off] = color;
            }
        }
    }
}


