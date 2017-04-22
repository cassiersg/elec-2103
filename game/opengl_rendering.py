
import game_global as gg
import opengl.cubes as cubes
import opengl.compression as compression
import opengl.font as font
import utils
import pygame
import pickle
import random
import os
import time

assert gg.M == cubes.m
assert gg.N == cubes.n

v = []
def log_args(fname, grid, players_xy, player_id, round_gauge, global_gauge, score):
    global v
    if v is not None and random.random() < 0.05:
        v.append((grid, players_xy, player_id, round_gauge, global_gauge, score))
        if len(v) >= 30:
            with open(fname, "wb") as f:
                pickle.dump(v, f)
                v = None
            print('finished collecting images')


class Renderer:
    def __init__(self, hw_interface):
        self.hw_interface = hw_interface
        cubes.cubes_init()

    def display(self, grid, players_xy, player_id,
                round_gauge, global_gauge, score, round_gauge_speed=0, round_gauge_state_update_time=0):
        fname = os.environ.get('LOG_RENDER_ARGS')
        if fname is not None:
            log_args(fname,
                grid, players_xy, player_id, round_gauge, global_gauge, score)
            return
        t0 = time.time()
        round_gauge -= int((time.time() - round_gauge_state_update_time)*round_gauge_speed*1000)
        round_gauge = max(round_gauge, 1)
        #print('speed', round_gauge_speed, 'dt', time.time() - round_gauge_state_update_time)
        grid = bytearray(x for y in grid for x in y)
        p1x, p1y, p2x, p2y = players_xy
        t1 = time.time()
        cubes.draw_cubes(grid, gg.N, gg.M, p1x, p1y, p2x, p2y, player_id, round_gauge)
        t2 = time.time()
        pixel_buf = bytearray(cubes.width*cubes.height*4)
        cubes.cubes_image_export(pixel_buf)
        t3 = time.time()
        mask = font.render_text(str(score))
        t31 = time.time()
        font.blit_mask(pixel_buf, cubes.width, cubes.height, mask, 0, 0, 0xffffff)
        t4 = time.time()
        #print('setup', t1-t0, 'draw', t2-t1, 'export', t3-t2, 'gen mask', t31-t3, 'blit mask', t4-t3)
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

