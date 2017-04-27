import os
import pickle
import logging

import pygame
from pygame.locals import *

import game_global as gg
import net

form_factor = (800, 480)

class HardwareInterface:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode(form_factor)
        pygame.display.set_caption("Shape Yourself, Wall is Coming!")
        self.cur_acc_value = 100
        self.cur_raw_acc_value_y = 0

    def get_events(self):
        quit = False
        events = []
        for event in pygame.event.get():
            if event.type == QUIT:
                quit = True
            elif event.type == KEYDOWN:
                if event.key == pygame.K_k:
                    events.append(gg.TAP_LEFT)
                elif event.key == pygame.K_m:
                    events.append(gg.TAP_RIGHT)
                elif event.key == pygame.K_o:
                    logging.info("[CLIENT] Client increases accelerometer angle")
                    self.cur_acc_value = min(255, self.cur_acc_value+10)
                elif event.key == pygame.K_l:
                    logging.info("[CLIENT] Client decreases accelerometer angle")
                    self.cur_acc_value = max(0, self.cur_acc_value-10)
                elif event.key == pygame.K_q:
                    logging.info("[CLIENT] changes y inclination towards left")
                    self.cur_raw_acc_value_y += 1
                elif event.key == pygame.K_d:
                    logging.info("[CLIENT] changes y inclination towards right")
                    self.cur_raw_acc_value_y -= 1
                elif event.key == pygame.K_p:
                    logging.info("[CLIENT] Client wants to pause/resume the game")
                    events.append(gg.TWO_FINGER_SWIPE)

        return (quit, self.cur_acc_value, self.cur_raw_acc_value_y, events)

