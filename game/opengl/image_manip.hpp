#ifndef __H_IMAGE_MANIP_H_
#define __H_IMAGE_MANIP_H_

#include <stdlib.h>

void blit_image(
        unsigned char *img, size_t img_size,
        unsigned int img_width, unsigned int img_height,
        unsigned char *mask, size_t mask_size,
        unsigned int mask_width, unsigned int mask_height,
        unsigned int x_off, unsigned int y_off,
        unsigned int color);


#endif

