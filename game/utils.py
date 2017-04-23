import socket

from datetime import datetime
from datetime import timedelta

import logging
from logging.handlers import RotatingFileHandler

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

is_rpi = 'raspberry' in socket.gethostname()
def runs_on_rpi():
    return is_rpi

def setup_log(logfile=None, print_stderr=True):
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter('%(asctime)s :: %(levelname)s :: %(message)s')
    if logfile is not None:
        file_handler = RotatingFileHandler(logfile, 'a', 100000, 1)
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    if print_stderr:
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(logging.DEBUG)
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

    logging.info('Starting loggging')

