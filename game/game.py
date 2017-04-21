from game_backend import GridState

from game_global import GAUGE_STATE_INIT
from game_global import ROUND_GAUGE_SPEED_INIT
from game_global import GLOBAL_GAUGE_SPEED
from game_global import M, N

from utils import Timer

class GameState:
    def __init__(self):
        self.grid_state = GridState(M, N)

        self.score = 0

        self.round_gauge_level = GAUGE_STATE_INIT
        self.round_gauge_speed = ROUND_GAUGE_SPEED_INIT
        self.round_gauge_speed_factor = 1.0

        self.global_gauge_level = GAUGE_STATE_INIT
        self.global_gauge_speed = GLOBAL_GAUGE_SPEED

        self.timer = Timer()
        self.last_gauge_update_time = self.timer.get_time_ms()

    def update_gauges_level(self):
        current_time = self.timer.get_time_ms()
        elapsed_time = current_time - self.last_gauge_update_time
        self.last_gauge_update_time = current_time

        eff_speed = self.round_gauge_speed_factor * self.round_gauge_speed
        self.round_gauge_level -= eff_speed * elapsed_time

        self.global_gauge_level -= self.global_gauge_speed * elapsed_time

    def update_speed_factor(self, angles):
        self.round_gauge_speed_factor += sum(angles)/255.0

    def is_game_finished(self):
        self.update_gauges_level()
        return self.global_gauge_level <= 0

    def is_round_finished(self):
        self.update_gauges_level()
        return self.round_gauge_level <= 0

    # Returns True or False so that the server can properly send an eventual
    # END ROUND message.
    def start_next_round(self):
        assert self.is_round_finished()

        self.round_gauge_level = GAUGE_STATE_INIT
        self.round_gauge_speed = ROUND_GAUGE_SPEED_INIT
        self.round_gauge_speed_factor = 1.0

        self.timer = Timer()
        self.last_gauge_update_time = self.timer.get_time_ms()

        if self.grid_state.is_winning():
            self.score += 1
            self.grid_state = GridState(M, N)
            return True
        else:
            self.score = 0
            self.grid_state = GridState(M, N)

            self.global_gauge_level = GAUGE_STATE_INIT
            self.global_gauge_speed = GLOBAL_GAUGE_SPEED

            return False

    def pause(self):
        self.timer.pause()

    def resume(self):
        self.timer.resume()
