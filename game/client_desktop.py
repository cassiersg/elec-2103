import os
import pickle
import pygame
import game_global as gg
from pygame.locals import *
import net
from tiles import TILE_X, TILE_Y, TILE_SIZE, TILE_NB, BLACK, colormap, tiles_image

form_factor = (800, 480) # for opengl renderer
#form_factor = (480, 800) # for tiling renderer

class HardwareInterface:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode(form_factor)
        self.screen.fill(BLACK)
        pygame.display.set_caption("Shape Yourself, Wall is Coming!")

    def display_tiles(self, tile_idx):
        s = pygame.Surface((TILE_X*TILE_SIZE, TILE_Y*TILE_SIZE))
        for i in range(TILE_X*TILE_Y):
            t = tile_idx[i]
            coord_x =  TILE_SIZE*(i % TILE_X)
            coord_y = TILE_SIZE*(i // TILE_X)
            s.blit(tiles_surfaces[t], (coord_x, coord_y))
        s = pygame.transform.rotate(s, 90)
        self.screen.blit(s, (0, 0))
        pygame.display.flip()
        
    def get_events(self, cur_acc_value):
        quit = False
        events = []
        for event in pygame.event.get():
            if event.type == QUIT:
                quit = True
            elif event.type == KEYDOWN:
                if event.key == pygame.K_k:
                    print("[CLIENT] Client sends left movement.")
                    events.append(net.LEFT)
                elif event.key == pygame.K_m:
                    print("[CLIENT] Client sends right movement.")
                    events.append(net.RIGHT)
                elif event.key == pygame.K_o:
                    print("[CLIENT] Client increases accelerometer angle")
                    cur_acc_value = min(255, cur_acc_value+10)
                elif event.key == pygame.K_l:
                    print("[CLIENT] Client decreases accelerometer angle")
                    cur_acc_value = max(0, cur_acc_value-10)
        return (quit, cur_acc_value, events)


tiles_surfaces = []
for i in range(TILE_NB):
    s = pygame.Surface((TILE_SIZE, TILE_SIZE))
    for j in range(TILE_SIZE**2):
        c = tiles_image[i*TILE_SIZE**2+j]
        s.set_at((j % TILE_SIZE, j // TILE_SIZE), colormap[c])
    tiles_surfaces.append(s)

