
import time
import pickle
import client_desktop
import tile_rendering

grid = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3],
    [3, 3, 0, 4, 3, 0, 0, 0, 3, 3, 0, 3, 3, 3, 3],
    [3, 3, 0, 3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 3, 3],
    [3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 0, 4, 3, 3, 3],
    [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
    [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]]
players_xy = [0, 1, 14, 1]
player_id = 2
round_gauge_state = 45438
global_gauge_state = 63525
score = 3

d = client_desktop.HardwareInterface()
r = rendering.Renderer(d)

t0 = time.time()
r.display(grid, players_xy, player_id, round_gauge_state, global_gauge_state, score)
print(time.time() - t0)
time.sleep(100)

