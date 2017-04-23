
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

    def display(self, gamestate):
        gamestate.current_time = time.time() # a small hack, but allow for clean decoding after-the-fact
        fname = os.environ.get('LOG_RENDER_ARGS')
        if fname is not None:
            log_args(fname, gamestate) 
            return
        pixel_buf = scene_draw.render_gamestate(gamestate)
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

