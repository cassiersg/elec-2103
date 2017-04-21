#ifndef __H_CUBES_H_
#define __H_CUBES_H_

const int width = 800;
const int height = 480;

const int m = 15;
const int n = 7;

void draw_cubes(unsigned char *grid, int grid_size, int n, int m, int p1x, int p1y, int p2x, int p2y, int player_id, int round_gauge);

void cubes_init();
void cubes_exit();
void cubes_image_export(unsigned char *buf, int buf_size);

#endif

