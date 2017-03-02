import random as r
import pygame
import sys
import time

from pygame.locals import *


# Grid elements
HOLE = -3
WALL = -2
STRUCT = -1
P1 = 1
P2 = 2
TIMEOUT = 10

# Grid size
M = 15
N = 7

# Pygame constants
WINSIZE = [800, 480]
CASE_SIZE = 40

BLACK = (  0,   0,   0)
GREY  = (192, 192, 192)
WHITE = (255, 255, 255)
RED   = (255,   0,   0)
GREEN = (  0, 255,   0)
BLUE  = (  0,   0, 255)

def build_grid(m, n):
    if m < 3 or n < 3:
        return None

    # Starting from a full wall
    grid = [[WALL for i in range(m)] for j in range(n)]

    # Adding the floor
    grid[0][:] = [STRUCT for i in range(m)]

    # Adding players
    grid[1][0] = P1
    grid[1][m-1] = P2

    # List of possible ordered (from "left" to "right") possible positions
    positions = [(0,1), (1,1)]

    # Adding some random structures
    for i in range(2, m-2):
        length = r.randint(0, n-3)

        curr_x = i
        curr_y = 1

        positions_right = list()
        for j in range(length):
            # Avoid empty space of width one between two columns
            if grid[curr_y][curr_x-2] == STRUCT and grid[curr_y][curr_x-1] != STRUCT:
                break
            else:
                grid[curr_y][curr_x] = STRUCT

                if (curr_x, curr_y) in positions:
                    positions.remove((curr_x, curr_y))

                if grid[curr_y][curr_x-1] == WALL and (curr_x-1, curr_y) not in positions:
                    positions.append((curr_x-1, curr_y))

                if grid[curr_y][curr_x+1] == WALL and (curr_x+1, curr_y) not in positions:
                    positions_right.append((curr_x+1, curr_y))

            curr_y += 1

        if grid[curr_y][curr_x] == WALL and (curr_x, curr_y) not in positions:
            positions.append((curr_x, curr_y))

        positions_right.reverse()
        positions.extend(positions_right)

    if (m-2, 1) not in positions:
        positions.append((m-2, 1))

    # Setting two random holes in the grid
    idx = list(range(1, len(positions)-1))
    r.shuffle(idx)
    holes = [positions[idx[0]], positions[idx[1]]]

    grid[holes[0][1]][holes[0][0]] = HOLE
    grid[holes[1][1]][holes[1][0]] = HOLE

    positions.append((m-1, 1))

    return (grid, positions, holes)

def move_left(grid, player_id, player_pos, positions, holes):
    (x, y) = positions[player_pos]

    if grid[y][x] != player_id or player_pos <= 0:
        return player_pos

    (x_next, y_next) = positions[player_pos-1]
    if grid[y_next][x_next] not in [WALL, HOLE]:
        return player_pos

    grid[y][x] = HOLE if (x, y) in holes else WALL
    grid[y_next][x_next] = player_id
    return player_pos-1

def move_right(grid, player_id, player_pos, positions, holes):
    (x, y) = positions[player_pos]

    if grid[y][x] != player_id or player_pos >= len(positions) - 1:
        return player_pos

    (x_next, y_next) = positions[player_pos+1]
    if grid[y_next][x_next] not in [WALL, HOLE]:
        return player_pos

    grid[y][x] = HOLE if (x, y) in holes else  WALL
    grid[y_next][x_next] = player_id
    return player_pos+1

def draw_grid(display, grid):
    m = len(grid)
    n = len(grid[0])

    for i in range(m):
        for j in range(n):
            if grid[m-i-1][j] == STRUCT:
                draw_case(display, WHITE, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == WALL:
                draw_case(display, GREY, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == P1:
                draw_case(display, RED, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == P2:
                draw_case(display, GREEN, j*CASE_SIZE, i*CASE_SIZE)
            elif grid[m-i-1][j] == HOLE:
                draw_case(display, BLACK, j*CASE_SIZE, i*CASE_SIZE)

def draw_case(display, color, x, y):
    pygame.draw.rect(display, color, (x, y, CASE_SIZE, CASE_SIZE))

def draw_timer(display, elapsed_time):
    per_remaining = (TIMEOUT-elapsed_time)/TIMEOUT

    if per_remaining < 0:
        return

    timer_height = per_remaining*N*CASE_SIZE

    pygame.draw.rect(display, BLACK, (M*CASE_SIZE+2, 0, 38, N*CASE_SIZE-timer_height))
    pygame.draw.rect(display, BLUE, (M*CASE_SIZE+2, N*CASE_SIZE-timer_height, 38, timer_height))

def write_score(display, font, value):
    pygame.draw.rect(display, BLACK, (0, N*CASE_SIZE, M*CASE_SIZE, 40))
    score_text = font.render("Score: " + str(value), 1, WHITE)
    display.blit(score_text, (0, N*CASE_SIZE))

def main():
    pygame.init()
    screen = pygame.display.set_mode(((M+1)*CASE_SIZE, (N+1)*CASE_SIZE))
    screen.fill(BLACK)
    pygame.display.set_caption("Shape Yourself, Wall is Coming!")

    (grid, positions, holes) = build_grid(M,N)
    p1_pos = 0
    p2_pos = len(positions)-1
    score = 0

    myfont = pygame.font.SysFont("Comic Sans MS", 28)
    draw_grid(screen, grid)

    start_time = pygame.time.get_ticks()
    start_loop_time = start_time
    total_time = 0

    speed_factor = 1.0

    while True:
        time.sleep(0.01)

        for event in pygame.event.get():
            if event.type == QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == KEYDOWN:
                if event.key == pygame.K_q:
                    p1_pos = move_left(grid, P1, p1_pos, positions, holes)
                elif event.key == pygame.K_d:
                    p1_pos = move_right(grid, P1, p1_pos, positions, holes)
                elif event.key == pygame.K_k:
                    p2_pos = move_left(grid, P2, p2_pos, positions, holes)
                elif event.key == pygame.K_m:
                    p2_pos = move_right(grid, P2, p2_pos, positions, holes)
                elif event.key == pygame.K_z:
                    speed_factor = speed_factor + 0.2
                    print("Faster:" + str(speed_factor))
                elif event.key == pygame.K_o:
                    speed_factor = max(0, speed_factor-0.2)
                    print("Slower:" + str(speed_factor))

        draw_grid(screen, grid)
        loop_time = pygame.time.get_ticks() - start_loop_time
        start_loop_time = pygame.time.get_ticks()

        total_time = speed_factor*loop_time/1000 + total_time

        if total_time > TIMEOUT:
            if set([positions[p1_pos], positions[p2_pos]]) == set(holes):
                score = score + 1
            else:
                score = 0

            start_time = pygame.time.get_ticks()
            start_loop_time = start_time
            total_time = 0

            speed_factor = 1.0

            (grid, positions, holes) = build_grid(M,N)
            p1_pos = 0
            p2_pos = len(positions)-1

        draw_timer(screen, total_time)
        write_score(screen, myfont, score)
        pygame.display.update()

if __name__ == "__main__":
    main()
