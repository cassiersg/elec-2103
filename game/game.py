import pygame
from pygame.locals import *
import time
import sys

import game_global as gg
import game_frontend as gf
import game_backend as gb

def main():
    screen = gf.pygame_init()

    (grid, positions, holes) = gb.init_round(gg.M,gg.N)
    p1_pos = 0
    p2_pos = len(positions)-1
    score = 0

    myfont = pygame.font.SysFont("Comic Sans MS", 28)
    gf.draw_grid(screen, grid)

    game_start_time = pygame.time.get_ticks()
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
                    p1_pos = gb.move_left(grid, gg.P1, p1_pos, positions, holes)
                elif event.key == pygame.K_d:
                    p1_pos = gb.move_right(grid, gg.P1, p1_pos, positions, holes)
                elif event.key == pygame.K_k:
                    p2_pos = gb.move_left(grid, gg.P2, p2_pos, positions, holes)
                elif event.key == pygame.K_m:
                    p2_pos = gb.move_right(grid, gg.P2, p2_pos, positions, holes)
                elif event.key == pygame.K_z:
                    speed_factor = speed_factor + 0.2
                elif event.key == pygame.K_o:
                    speed_factor = max(0.4, speed_factor-0.2)

        gf.draw_grid(screen, grid)
        loop_time = pygame.time.get_ticks() - start_loop_time
        start_loop_time = pygame.time.get_ticks()

        total_time = speed_factor*loop_time/1000 + total_time

        if total_time > gg.ROUND_TIMEOUT:
            if set([positions[p1_pos], positions[p2_pos]]) == set(holes):
                score = score + 1
            else:
                game_start_time = pygame.time.get_ticks()
                score = 0

            start_time = pygame.time.get_ticks()
            start_loop_time = start_time
            total_time = 0

            speed_factor = 1.0

            (grid, positions, holes) = gb.init_round(gg.M, gg.N)
            p1_pos = 0
            p2_pos = len(positions)-1

        game_total_time = (pygame.time.get_ticks() - game_start_time)/1000

        if game_total_time > gg.GAME_TIMEOUT:
            print("Game over! Score: " + str(score))
            pygame.quit()
            sys.exit()

        gf.draw_round_timer(screen, total_time)
        gf.draw_game_timer(screen, game_total_time)
        gf.write_score(screen, myfont, score)
        pygame.display.update()

if __name__ == "__main__":
    main()
