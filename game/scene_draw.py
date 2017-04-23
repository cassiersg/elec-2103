
import game_global as gg
import opengl.cubes as cubes
import opengl.font as font
import math
image_manip = font.image_manip

assert gg.M == cubes.m
assert gg.N == cubes.n

def render_gamestate(gamestate):
    if gamestate.game_finished:
        pixel_buf = scene_text("Game finished ! Your score: {}".format(gamestate.score))
    elif not gamestate.connected:
        pixel_buf = scene_text("Connecting to server")
    elif not gamestate.client_ready:
        pixel_buf = scene_text("Tap to start game")
    elif gamestate.game_started:
        # todo handle case round_running == False (and round_outcome is None => before any game,
        # and round_outcome is not None => end of round => color wall)
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
            gamestate.score)
        if gamestate.paused:
            mask = font.render_text("Pause")
            font.blit_mask(
                pixel_buf, cubes.width, cubes.height,
                mask,
                *offset_center_mask(mask, y_c = 420),
                0xffffffff)
    elif gamestate.client_ready and not gamestate.game_started:
        pixel_buf = scene_text("Waiting for other player")
    else:
        pixel_buf = scene_text("Unknown state")
    return pixel_buf

def scene_cubes(grid, players_xy, player_id,
            actual_round_gauge, global_gauge, score):
    grid = bytearray(x for y in grid for x in y)
    p1x, p1y, p2x, p2y = players_xy
    cubes.draw_cubes(grid, gg.N, gg.M, p1x, p1y, p2x, p2y, player_id, actual_round_gauge)
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    cubes.cubes_image_export(pixel_buf)
    mask = font.render_text(str(score), font_size=80)
    font.blit_mask(pixel_buf, cubes.width, cubes.height, mask, 5, 5, 0xffffffff)
    image_manip.draw_rect(
        pixel_buf, cubes.width, cubes.height,
        0, 470,
        int(math.floor(global_gauge/gg.GAUGE_STATE_INIT*cubes.width)), 10,
        0xffffff)
    return pixel_buf

def scene_text(text, fg = 0xffffffff, bg = 0xff000000, font_size=60):
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    image_manip.draw_rect(
        pixel_buf, cubes.width, cubes.height,
        0, 0, cubes.width, cubes.height,
        bg)
    mask = font.render_text(text, font_size=font_size)
    (mw, mh), _ = mask
    off_x = max(0, (cubes.width - mw)//2)
    off_y = max(0, (cubes.height - mh)//2)
    font.blit_mask(
        pixel_buf, cubes.width, cubes.height,
        mask,
        *offset_center_mask(mask),
        fg)
    return pixel_buf

def offset_center_mask(mask, x_c = cubes.width//2, y_c = cubes.height//2):
    (mw, mh), _ = mask
    off_x = max(0, x_c - mw//2)
    off_y = max(0, y_c - mh//2)
    return off_x, off_y

