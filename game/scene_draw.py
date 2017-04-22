
import game_global as gg
import opengl.cubes as cubes
import opengl.font as font
import math

assert gg.M == cubes.m
assert gg.N == cubes.n


def draw_scene(grid, players_xy, player_id,
            actual_round_gauge, global_gauge, score):
    grid = bytearray(x for y in grid for x in y)
    p1x, p1y, p2x, p2y = players_xy
    cubes.draw_cubes(grid, gg.N, gg.M, p1x, p1y, p2x, p2y, player_id, actual_round_gauge)
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    cubes.cubes_image_export(pixel_buf)
    mask = font.render_text(str(score))
    font.blit_mask(pixel_buf, cubes.width, cubes.height, mask, 0, 0, 0xffffff)
    font.image_manip.draw_rect(
        pixel_buf, cubes.width, cubes.height,
        0, 470,
        int(math.floor(global_gauge/gg.GAUGE_STATE_INIT*cubes.width)), 10,
        0xffffff)
    return pixel_buf

