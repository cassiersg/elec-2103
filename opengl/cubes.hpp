#ifndef __H_CUBES_H_
#define __H_CUBES_H_

const int width = 800;
const int height = 480;

void draw_cubes(void);

void cubes_init();
void cubes_exit();
void cubes_image_export(unsigned char *str, int buf_size);

#endif

