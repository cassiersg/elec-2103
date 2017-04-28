
import math
import itertools

import client_core
import time
import net
import game_global as gg
import opengl.cubes as cubes
import opengl.font as font
image_manip = font.image_manip

assert gg.M == cubes.m
assert gg.N == cubes.n

player_colors = [0xff0000, 0xffff00]
player_color_names = ["red", "yellow"]

color_win = 0x00a000
color_loose = 0xf4a742
dark_gray = 0x808080
white = 0x000000

class Filter():
    def __init__(self, size):
        self.size = size
        self.buf = [0] * size
        self.cur = 0

    def add(self, val):
        self.buf[self.cur] = val
        self.cur = (self.cur + 1) % self.size

    def get_mean(self):
        return sum(self.buf)/self.size

f = Filter(10)

def render_gamestate(gamestate):
    if gamestate.game_finished:
        pixel_buf = scene_texts(["Game finished !", "Your score: {}".format(gamestate.score)])
    elif not gamestate.connected:
        pixel_buf = scene_texts(["Connecting to server"])
    elif not gamestate.client_ready:
        pixel_buf = scene_texts(
            ["What's the goal?",
            " ", " ",
            "You're a cube, and you want to fit in the holes of a",
            " ",
            "a moving wall to survive! You have to pass in as much walls",
            " ",
            "as possible in the given time. Each passed wall is worth 1 point.",
            " ",
            "Failing to pass a wall will make you loose 1 point.",
            " ", " ", " ", " ", " ",
            "How to play?",
            " ", " ",
            "- Touch the right side of the screen to go right",
            " ",
            "(I suppose you guessed how to go left)",
            " ",
            "- Do a two-finger vertical swipe to pause",
            " ",
            "- Tilt the screen to either change the point of",
            " ",
            "view or change the speed of the wall",
            " ",
            "- Press the screen with 3 fingers to make the wall more",
            " ",
            "visible during 2s (only once per round)"],
            font_size = [40, 30, 30, 20, 30, 20, 30, 20, 30, 20, 30, 30, 30, 30, 30, 40, 30,
                         30, 20, 30, 15, 30, 20,
                         30, 20, 30, 20, 30, 20, 30])

    elif gamestate.game_started:
        if (not gamestate.players_states[0].is_valid() or
            (not gamestate.round_running and gamestate.round_outcome) is None):
            # not yet received first position, don't update display
            # or game started, no grid received...
            return None
        pixel_buf = scene_cubes(gamestate)
        if gamestate.paused:
            scene_texts(
                ["Paused", "Please do a two-finger vertical swipe to resume"],
                fg = color_loose,
                pixel_buf = pixel_buf,
                font_size = [70, 20],
                y_c = 0.7)
        if gamestate.current_time - gamestate.game_start_time < 3 and gamestate.player_id != 42: # not spectator
            scene_texts(
                ["Your color is {}".format(player_color_names[gamestate.player_id-1])],
                fg = player_colors[gamestate.player_id-1],
                pixel_buf = pixel_buf,
                y_c = 0.9,
                font_size=40
            )
    elif gamestate.client_ready and not gamestate.game_started:
        pixel_buf = scene_texts(["Waiting for other player", "Be ready!"],
                                font_size =  [40, 30])
    else:
        pixel_buf = scene_texts(["Unknown state"])
    cubes.cubes_image_normalize(pixel_buf)
    return pixel_buf

def get_player_pos_st(player_idx, gamestate):
    p = gamestate.players_states[player_idx]
    if p.is_moving(gamestate.current_time):
        offset_x, offset_y, angle = client_core.get_rot_angle(p, gamestate.grid)
        angle *= p.rotation_fraction(gamestate.current_time)
        px, py = p.prev_pos
    else:
        offset_x = offset_y = 0
        angle = 0.0
        px, py = p.curr_pos
    return px, py, offset_x, offset_y, angle

def scene_cubes(gamestate):
    # round gauge
    round_gauge = gamestate.round_gauge_state
    if not gamestate.paused:
        dt = gamestate.current_time - gamestate.round_gauge_state_update_time
        round_gauge -= int(dt * gamestate.round_gauge_speed * 1000)
        round_gauge = max(round_gauge, 1)
    # wall wolor
    if gamestate.round_running:
        wall_color = 0xffffff
    elif gamestate.round_outcome == net.WIN:
        wall_color = color_win
    elif gamestate.round_outcome == net.LOOSE:
        wall_color = color_loose
    else:
        raise ValueError(gamestate.round_outcome)
    # grid
    grid = bytearray(x for y in gamestate.grid for x in y)

    # players
    p1x, p1y, off_x1, off_y1, angle1 = get_player_pos_st(0, gamestate)
    p2x, p2y, off_x2, off_y2, angle2 = get_player_pos_st(1, gamestate)

    f.add(gamestate.raw_acc_value_y/10)
    x_offset = round(max(-10.0, min(f.get_mean(), 10.0)))

    if gamestate.hide_struct and (time.time() -
    gamestate.hide_struct_start_time >= 1.5):
        gamestate.hide_struct = False

    # draw cubes
    cubes.draw_cubes(
        grid, gg.N, gg.M,
        p1x, p1y, p2x, p2y,
        round_gauge,
        wall_color,
        x_offset,
        off_x1, off_y1, angle1,
        off_x2, off_y2, angle2,
        255, 255,
        gamestate.hide_struct)
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    cubes.cubes_image_export(pixel_buf)
    # display score
    scene_texts(
        ["{:d}".format(gamestate.score)],
        font_size=60,
        pixel_buf=pixel_buf,
        x_c = 0.08, # enough to hold 4 digits...
        y_c = 0.06)
    # global gauge
    image_manip.draw_rect(
        pixel_buf, cubes.width, cubes.height,
        0, 470,
        int(math.floor(
            gamestate.global_gauge_state/gg.GAUGE_STATE_INIT*cubes.width)
        ),
        10,
        0xffffff)
    return pixel_buf

def scene_texts(
    texts=(),
    fg = 0xffffffff,
    bg = None,
    font_size=60,
    pixel_buf = None,
    x_c = 0.5,
    y_c = 0.5):
    if pixel_buf is None:
        pixel_buf = bytearray(cubes.width*cubes.height*4)
    if bg is not None:
        image_manip.draw_rect(
            pixel_buf, cubes.width, cubes.height,
            0, 0, cubes.width, cubes.height,
            bg)
    draw_texts(pixel_buf, texts, fg, font_size, round(cubes.width*x_c), round(cubes.height*y_c))
    return pixel_buf

def draw_texts(pixel_buf, texts, fg, font_size, x_c, y_c):
    masks = []
    n = len(texts)
    if isinstance(font_size, int):
        font_size = itertools.repeat(font_size)
    for t, fs in zip(texts, font_size):
        masks.append(font.render_text(t, font_size=fs))
    sum_height = sum(h for (_, h), _ in masks)*1.1
    v_offs = [round((i-(n-1)/2)*sum_height/n) for i in range(n)]
    for mask, v_sup_off in zip(masks, v_offs):
        off_x, off_y = offset_center_mask(mask, x_c, y_c)
        font.blit_mask(
            pixel_buf, cubes.width, cubes.height,
            mask,
            off_x, v_sup_off + off_y,
            fg)

def offset_center_mask(mask, x_c, y_c):
    (mw, mh), _ = mask
    off_x = max(0, x_c - mw//2)
    off_y = max(0, y_c - mh//2)
    return off_x, off_y

