
import math
import itertools

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

def render_gamestate(gamestate):
    if gamestate.game_finished:
        pixel_buf = scene_texts(["Game finished !", "Your score: {}".format(gamestate.score)])
    elif not gamestate.connected:
        pixel_buf = scene_texts(["Connecting to server"])
    elif not gamestate.client_ready:
        pixel_buf = scene_texts(["Tap to start game"])
    elif gamestate.game_started:
        if gamestate.players_xy is None:
            # not yet received first position, don't update display
            return None
        if gamestate.round_running:
            wall_color = 0xffffff
        elif gamestate.round_outcome is None:
            # game started, no grid received...
            return None
        elif gamestate.round_outcome == net.WIN:
            wall_color = color_win
        elif gamestate.round_outcome == net.LOOSE:
            wall_color = color_loose
        else:
            raise ValueError(gamestate.round_outcome)
        round_gauge = gamestate.round_gauge_state
        if not gamestate.paused:
            dt = gamestate.current_time - gamestate.round_gauge_state_update_time
            round_gauge -= int(dt * gamestate.round_gauge_speed * 1000)
        round_gauge = max(round_gauge, 1)
        pixel_buf = scene_cubes(
            gamestate.grid,
            gamestate.players_xy,
            gamestate.player_id,
            round_gauge,
            gamestate.global_gauge_state,
            gamestate.score,
            wall_color)
        if gamestate.paused:
            scene_texts(
                ["Paused", "Please do a two-finger swipe to resume"],
                fg = color_loose,
                pixel_buf = pixel_buf,
                font_size = [70, 20],
                y_c = 0.7)
        if gamestate.current_time - gamestate.game_start_time < 3:
            scene_texts(
                ["Your color is {}".format(player_color_names[gamestate.player_id-1])],
                fg = player_colors[gamestate.player_id-1],
                pixel_buf = pixel_buf,
                y_c = 0.9,
                font_size=40
            )

    elif gamestate.client_ready and not gamestate.game_started:
        pixel_buf = scene_texts(["Waiting for other player"])
    else:
        pixel_buf = scene_texts(["Unknown state"])
    return pixel_buf

def scene_cubes(grid, players_xy, player_id,
            actual_round_gauge, global_gauge, score, wall_color):
    grid = bytearray(x for y in grid for x in y)
    p1x, p1y, p2x, p2y = players_xy
    cubes.draw_cubes(grid, gg.N, gg.M, p1x, p1y, p2x, p2y, player_id, actual_round_gauge, wall_color)
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    cubes.cubes_image_export(pixel_buf)
    scene_texts(
        ["{:d}".format(score)],
        font_size=60,
        pixel_buf=pixel_buf,
        x_c = 0.08, # enough to hold 4 digits...
        y_c = 0.06)
    image_manip.draw_rect(
        pixel_buf, cubes.width, cubes.height,
        0, 470,
        int(math.floor(global_gauge/gg.GAUGE_STATE_INIT*cubes.width)), 10,
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
        print("draw_texts",
            cubes.width, cubes.height,
            mask[0],
            off_x, v_sup_off + off_y,
            fg)
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

