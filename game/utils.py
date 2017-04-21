import socket

from datetime import datetime
from datetime import timedelta

class Timer:
    def __init__(self):
        self.start_time = datetime.now()

        self.start_pause_time = 0
        self.total_paused_time = self.start_time - self.start_time
        self.paused = False

    def get_time_ms(self):
        assert not self.paused
        dt = datetime.now() - self.start_time - self.total_paused_time
        ms = (dt.days * 24 * 60 * 60 + dt.seconds) * 1000 + dt.microseconds / 1000.0
        return ms

    def reset(self):
        self.start_time = datetime.now()

    def pause(self):
        self.paused = True
        self.start_pause_time = datetime.now()

    def resume(self):
        self.paused = False
        self.total_paused_time += datetime.now() - self.start_pause_time

def flatten_grid(grid):
    return [item for sublist in grid for item in sublist]

def unflatten_grid(flat_grid, n, m):
    return [[flat_grid[i+j*n] for i in range(n)] for j in range(m)]

def runs_on_rpi():
    return 'raspberry' in socket.gethostname()

