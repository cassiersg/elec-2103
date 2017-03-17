import pygame
from game_frontend import *
from game_global import *
from utils import *
from pygame.locals import *

class HardwareInterface:
    def __init__(self):
        self.screen = pygame_init()

    def update_display(self, grid, player_id, round_gauge, global_gauge, score):
        myfont = pygame.font.SysFont("Comic Sans MS", 28)

        draw_grid(self.screen, grid, player_id)
        draw_round_timer(self.screen, round_gauge)
        write_score(self.screen, myfont, score)
        draw_global_timer(self.screen, global_gauge)

        pygame.display.update()

    def get_events(self, cur_acc_value):
        quit = False
        events = []

        for event in pygame.event.get():
            if event.type == QUIT:
                quit = True
            elif event.type == KEYDOWN:
                if event.key == pygame.K_k:
                    print("[CLIENT] Client sends left movement.")
                    events.append(LEFT)
                elif event.key == pygame.K_m:
                    print("[CLIENT] Client sends right movement.")
                    events.append(RIGHT)
                elif event.key == pygame.K_o:
                    print("[CLIENT] Client increases accelerometer angle")
                    cur_acc_value = min(255, cur_acc_value+10)
                elif event.key == pygame.K_l:
                    print("[CLIENT] Client decreases accelerometer angle")
                    cur_acc_value = max(0, cur_acc_value-10)

        return (quit, cur_acc_value, events)

