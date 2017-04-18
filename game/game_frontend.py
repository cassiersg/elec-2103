import pygame
import sys
import time

from game_global import *

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
    screen = pygame.display.set_mode(((M+2)*CASE_SIZE, (N+1)*CASE_SIZE))
    screen.fill(BLACK)
    pygame.display.set_caption("Shape Yourself, Wall is Coming!")
    return screen

def draw_grid(display, grid, players_xy, player_id):
    m = len(grid)
    n = len(grid[0])

    for i in range(m):
        for j in range(n):
            if grid[m-i-1][j] == STRUCT:
                draw_case(display, WHITE, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == WALL:
                draw_case(display, GREY, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == HOLE:
                draw_case(display, BLACK, j*CASE_SIZE, i*CASE_SIZE)
            else:
                ValueError(grid[m-i-1][j])

    x1, y1, x2, y2 = players_xy
    if player_id == 1:
        c1, c2 = RED, GREEN
    elif player_id == 2:
        c1, c2 = GREEN, RED
    else:
        raise ValueError(player_id)

    draw_case(display, c1, x1*CASE_SIZE, (m-y1-1)*CASE_SIZE)
    draw_case(display, c2, x2*CASE_SIZE, (m-y2-1)*CASE_SIZE)

def draw_case(display, color, x, y):
    pygame.draw.rect(display, color, (x, y, CASE_SIZE, CASE_SIZE))

def draw_round_timer(display, gauge_state):
    p = gauge_state/GAUGE_STATE_INIT

    pygame.draw.rect(display, BLACK, (M*CASE_SIZE+2, 0, 38, (1.0-p)*N*CASE_SIZE))
    pygame.draw.rect(display, BLUE, (M*CASE_SIZE+2,
                                     N*CASE_SIZE*(1.0-p),
                                     38, p*N*CASE_SIZE))

def draw_global_timer(display, gauge_state):
    p = gauge_state/GAUGE_STATE_INIT

    pygame.draw.rect(display, BLACK, ((M+1)*CASE_SIZE+2, 0, 38, (1.0-p)*N*CASE_SIZE))
    pygame.draw.rect(display, GREEN, ((M+1)*CASE_SIZE+2,
                                      N*CASE_SIZE*(1.0-p),
                                      38, p*N*CASE_SIZE))

def write_score(display, font, value):
    pygame.draw.rect(display, BLACK, (0, N*CASE_SIZE, M*CASE_SIZE, 40))
    score_text = font.render("Score: " + str(value), 1, WHITE)
    display.blit(score_text, (0, N*CASE_SIZE))
