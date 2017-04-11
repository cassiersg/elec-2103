
import game_global as gg
import opengl.cubes as cubes
import pygame

class Renderer:
    def __init__(self, hw_interface):
        self.hw_interface = hw_interface
        cubes.cubes_init()

    def display(self, grid, players_xy, player_id, round_gauge, global_gauge, score):
        # works only for desktop
        grid = bytearray(x for y in grid for x in y)
        p1x, p1y, p2x, p2y = players_xy
        cubes.draw_cubes(grid, 7, 15, p1x, p1y, p2x, p2y, player_id, round_gauge)
        buf = bytearray(cubes.width*cubes.height*4)
        cubes.cubes_image_export(buf)
        s = self.hw_interface.screen
        b = s.get_buffer()
        b.write(bytes(buf))
        pygame.display.flip()

