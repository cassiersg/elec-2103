
import pygame
import cubes

cubes.cubes_init()
cubes.draw_cubes()
buf = bytearray(cubes.width*cubes.height*4)
cubes.cubes_image_export(buf)
cubes.cubes_exit()
pygame.init()
s = pygame.display.set_mode((800, 480))
s.fill((0, 0, 0))
b = s.get_buffer()
b.write(bytes(buf))
pygame.display.flip()

import time
time.sleep(10)
