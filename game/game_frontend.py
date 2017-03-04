import pygame
import sys
import time

import game_global as gg

from pygame.locals import *

# PyGame drawing constants
CASE_SIZE   = 40

BLACK = (  0,   0,   0)
GREY  = (192, 192, 192)
WHITE = (255, 255, 255)
RED   = (255,   0,   0)
GREEN = (  0, 255,   0)
BLUE  = (  0,   0, 255)

def pygame_init():
    pygame.init()
    screen = pygame.display.set_mode(((gg.M+2)*CASE_SIZE, (gg.N+1)*CASE_SIZE))
    screen.fill(BLACK)
    pygame.display.set_caption("Shape Yourself, Wall is Coming!")
    return screen

def draw_grid(display, grid):
    m = len(grid)
    n = len(grid[0])

    for i in range(m):
        for j in range(n):
            if grid[m-i-1][j] == gg.STRUCT:
                draw_case(display, WHITE, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == gg.WALL:
                draw_case(display, GREY, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == gg.P1:
                draw_case(display, RED, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == gg.P2:
                draw_case(display, GREEN, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == gg.HOLE:
                draw_case(display, BLACK, j*CASE_SIZE, i*CASE_SIZE)

def draw_case(display, color, x, y):
    pygame.draw.rect(display, color, (x, y, CASE_SIZE, CASE_SIZE))

def draw_round_timer(display, percentage):
    p = percentage/100.0

    pygame.draw.rect(display, BLACK, (gg.M*CASE_SIZE+2, 0, 38, (1.0-p)*gg.N*CASE_SIZE))
    pygame.draw.rect(display, BLUE, (gg.M*CASE_SIZE+2,
                                     gg.N*CASE_SIZE*(1.0-p),
                                     38, p*gg.N*CASE_SIZE))

def draw_game_timer(display, elapsed_time):
    per_remaining = (gg.GAME_TIMEOUT-elapsed_time)/gg.GAME_TIMEOUT

    if per_remaining < 0:
        return

    timer_height = per_remaining*gg.N*CASE_SIZE

    pygame.draw.rect(display, BLACK, ((gg.M+1)*CASE_SIZE+2, 0, 38, gg.N*CASE_SIZE-timer_height))
    pygame.draw.rect(display, GREEN, ((gg.M+1)*CASE_SIZE+2, gg.N*CASE_SIZE-timer_height, 38, timer_height))

def write_score(display, font, value):
    pygame.draw.rect(display, BLACK, (0, gg.N*CASE_SIZE, gg.M*CASE_SIZE, 40))
    score_text = font.render("Score: " + str(value), 1, WHITE)
    display.blit(score_text, (0, gg.N*CASE_SIZE))
