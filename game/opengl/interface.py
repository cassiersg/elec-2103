
import pygame
import cubes
import time
import font

import PIL

t0 = time.time()
grid = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3], [3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3], [3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]]
grid = bytearray(x for y in grid for x in y)

t1 = time.time()
cubes.cubes_init()
t2 = time.time()
cubes.draw_cubes(grid, cubes.n, cubes.m, 0, 1, 14, 1, 2, 20000)
buf = bytearray(cubes.width*cubes.height*4)
cubes.cubes_image_export(buf)
mask = font.render_text('a')
font.blit_mask(buf, 800, 480, mask, 100, 200, 0xff0000)
t3 = time.time()
cubes.cubes_exit()
pygame.init()
s = pygame.display.set_mode((800, 480))
s.fill((0, 0, 0))
b = s.get_buffer()
t4 = time.time()
b.write(bytes(buf))
pygame.display.flip()
t5 = time.time()

print("dt gen_grid", t1-t0)
print("dt init_cubes", t2-t1)
print("dt draw&recover buf", t3-t2)
print("dt blit buf", t5-t4)

time.sleep(10)
