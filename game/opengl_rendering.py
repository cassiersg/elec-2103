
import pickle
import random
import os
import time
import math
import logging
import io

from PIL import Image

import net
import game_global as gg
import utils
import scene_draw
import opengl.cubes as cubes
import opengl.font as font
if utils.is_rpi:
    import opengl.compression as compression
else:
    import pygame

assert gg.M == cubes.m
assert gg.N == cubes.n

v = []
def log_args(fname, gamestate):
    global v
    if gamestate.game_started and random.random() < 0.05:
        v.append(gamestate)
        if len(v) >= 30:
            with open(fname, "wb") as f:
                pickle.dump(v, f)
                v = None
            logging.info('finished collecting images')
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
        if pixel_buf is None:
            # invalid gamestate, wait
            return
        if utils.is_rpi:
            compressed_buf = bytearray(12000)
            n_chunks, output_used = compression.chunk_compress_huffman(
                pixel_buf, compressed_buf)
            self.hw_interface.send_spi_buf(list(compressed_buf[:4*output_used+4]))
        else:
            s = self.hw_interface.screen
            b = s.get_buffer()
            b.write(bytes(pixel_buf))
            pygame.display.flip()

    def update_player_images(self, p1_img, p2_img):
        img_size = (net.IMG_SIZE_PIX, net.IMG_SIZE_PIX)
        im1 = Image.open(io.BytesIO(p1_img)).resize(img_size).convert('RGBA').tobytes()
        im2 = Image.open(io.BytesIO(p2_img)).resize(img_size).convert('RGBA').tobytes()
        cubes.set_textures(
            bytearray(im1), bytearray(im2),
            net.IMG_SIZE_PIX, net.IMG_SIZE_PIX
        )

