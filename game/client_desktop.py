import os
import pickle
import pygame
import game_global as gg
from pygame.locals import *
import net

form_factor = (800, 480)

class HardwareInterface:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode(form_factor)
        pygame.display.set_caption("Shape Yourself, Wall is Coming!")
        self.cur_acc_value = 100

    def get_events(self):
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
                    self.cur_acc_value = min(255, self.cur_acc_value+10)
                elif event.key == pygame.K_l:
                    print("[CLIENT] Client decreases accelerometer angle")
                    self.cur_acc_value = max(0, self.cur_acc_value-10)
                elif event.key == pygame.K_p:
                    print("[CLIENT] Client wants to pause/resume the game")
                    events.append(net.PAUSE)

        return (quit, self.cur_acc_value, events)

