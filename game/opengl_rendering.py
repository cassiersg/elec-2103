
import game_global as gg
import opengl.cubes as cubes
import opengl.compression as compression
import utils
import pygame
import pickle
import random
import os

v = []
def log_args(grid, players_xy, player_id, round_gauge, global_gauge, score):
    global v
    if v is not None and random.random() < 0.05:
        v.append((grid, players_xy, player_id, round_gauge, global_gauge, score))
        if len(v) >= 30:
            with open("display_args.pkl", "wb") as f:
                pickle.dump(v, f)
                v = None


class Renderer:
    def __init__(self, hw_interface):
        self.hw_interface = hw_interface
        cubes.cubes_init()

    def display(self, grid, players_xy, player_id,
                round_gauge, global_gauge, score):
        grid = bytearray(x for y in grid for x in y)
        p1x, p1y, p2x, p2y = players_xy
        cubes.draw_cubes(grid, 7, 15, p1x, p1y, p2x, p2y, player_id, round_gauge)
        pixel_buf = bytearray(cubes.width*cubes.height*4)
        cubes.cubes_image_export(pixel_buf)
        if utils.is_rpi:
            compressed_buf = bytearray(12000)
            n_chunks, output_used = compression.chunk_compress_huffman(
                pixel_buf, compressed_buf, 32)
            self.hw_interface.send_spi_buf(list(compressed_buf))
            self.hw_interface.pageflip()
        else:
            if os.environ.get('LOG_RENDER_ARGS'):
                log_args(
                    grid, players_xy, player_id, round_gauge, global_gauge, score)
            s = self.hw_interface.screen
            b = s.get_buffer()
            b.write(bytes(pixel_buf))
            pygame.display.flip()

