import os
import pickle
import pygame
import game_global as gg
from pygame.locals import *
import net

class HardwareInterface:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((TILE_X*TILE_SIZE, TILE_Y*TILE_SIZE))
        self.screen.fill(BLACK)
        pygame.display.set_caption("Shape Yourself, Wall is Coming!")

    def display_tiles(self, tile_idx):
        for i in range(TILE_X*TILE_Y):
            t = tile_idx[i]
            coord_x =  TILE_SIZE*(i % TILE_X)
            coord_y = TILE_SIZE*(i // TILE_X)
            self.screen.blit(tiles_surfaces[t], (coord_x, coord_y))
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

TILE_SIZE = 8
TILE_NB = 100
TILE_X = 100
TILE_Y = 60

BLACK = (  0,   0,   0)
GRAY  = (192, 192, 192)
WHITE = (255, 255, 255)
RED   = (255,   0,   0)
GREEN = (  0, 255,   0)
BLUE  = (  0,   0, 255)

colormap = [
    BLACK,
    WHITE,
    RED,
    GREEN,
    GRAY,
]
colormap.extend((256-len(colormap))*[BLACK])

tiles_image = TILE_NB * TILE_SIZE**2 * [0]

for i in range(64):
    for j in range(16):
        tiles_image[i+j*TILE_SIZE**2] = 3 if i == 0 else j

for j in range(8):
    for i in range(8*j):
        tiles_image[i+(j+16)*TILE_SIZE**2] = 3 # green
    for i in range(8*j, TILE_SIZE**2):
        tiles_image[i+(j+16)*TILE_SIZE**2] = 2 # red

tiles_surfaces = []
for i in range(TILE_NB):
    s = pygame.Surface((TILE_SIZE, TILE_SIZE))
    for j in range(TILE_SIZE**2):
        c = tiles_image[i*TILE_SIZE**2+j]
        s.set_at((j % TILE_SIZE, j // TILE_SIZE), colormap[c])
    tiles_surfaces.append(s)

