
import game_global as gg
import opengl.cubes as cubes
import opengl.compression as compression
import opengl.font as font
import utils
import math
import pygame
import pickle
import random
import os
import time
import scene_draw

assert gg.M == cubes.m
assert gg.N == cubes.n

v = []
def log_args(fname, draw_scene_args):
    global v
    if v is not None and random.random() < 0.05:
        v.append(draw_scene_args)
        if len(v) >= 30:
            with open(fname, "wb") as f:
                pickle.dump(v, f)
                v = None
            print('finished collecting images')
            raise ValueError('finished')

class Renderer:
    def __init__(self, hw_interface):
        self.hw_interface = hw_interface
        cubes.cubes_init()

    def display(self, grid, players_xy, player_id,
                round_gauge, global_gauge, score, round_gauge_speed=0,
                round_gauge_state_update_time=0, paused=False):
        t0 = time.time()

        if not paused:
            round_gauge -= int((time.time() - round_gauge_state_update_time)*round_gauge_speed*1000)

        round_gauge = max(round_gauge, 1)
        draw_scene_args = (grid, players_xy, player_id, round_gauge, global_gauge, score)
        fname = os.environ.get('LOG_RENDER_ARGS')
        if fname is not None:
            log_args(fname, draw_scene_args) 
            return
        #print('speed', round_gauge_speed, 'dt', time.time() - round_gauge_state_update_time)
        t1 = time.time()
        pixel_buf = scene_draw.draw_scene(*draw_scene_args)
        t2 = time.time()
        #print('setup', t1-t0, 'draw, export, font', t2-t1)
        if utils.is_rpi:
            compressed_buf = bytearray(12000)
            n_chunks, output_used = compression.chunk_compress_huffman(
                pixel_buf, compressed_buf, 32)
            self.hw_interface.send_spi_buf(list(compressed_buf))
        else:
            s = self.hw_interface.screen
            b = s.get_buffer()
            b.write(bytes(pixel_buf))
            pygame.display.flip()

