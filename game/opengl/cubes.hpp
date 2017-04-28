#ifndef __H_CUBES_H_
#define __H_CUBES_H_

const int width = 800;
const int height = 480;

const int m = 15;
const int n = 6;

void draw_cubes(
        unsigned char *grid, int grid_size,
        int n, int m,
        int p1x, int p1y, int p2x, int p2y,
        int round_gauge,
        unsigned int wall_color,
        int x_offset,
        int off_x1, int off_y1, float angle1,
        int off_x2, int off_y2, float angle2,
        unsigned int p1_tex_intensity,
        unsigned int p2_tex_intensity,
        bool hide_struct
        );

void set_textures(
        unsigned int *texels1,
        size_t texels_len1,
        unsigned int *texels2,
        size_t texels_len2,
        unsigned int width,
        unsigned int height);

void cubes_init();
void cubes_exit();
void cubes_image_export(unsigned char *buf, int buf_size);
void cubes_image_normalize(unsigned int *buf, int buf_size);

#endif

