import time
import copy
import logging

import utils
import net
import game_global as gg

class GameFinished(Exception):
    pass

class ClientGameState:
    def __init__(self):
        self.grid = None
        self.score = 0
        self.round_gauge_state = gg.GAUGE_STATE_INIT
        self.global_gauge_state = gg.GAUGE_STATE_INIT
        self.round_gauge_speed = 0
        self.round_gauge_state_update_time = time.time()
        self.players_xy = None
        self.player_id = None
        self.raw_acc_value_y = 0
        self.game_start_time = None
        self.game_started = False
        self.client_ready = False
        self.paused = False
        self.connected = False
        self.round_running = False
        self.round_outcome = None
        self.game_finished = False

class Client:
    def __init__(self, packet_socket, hw_interface, display_args_glob, role):
        self.action_id = 0
        self.grid_id = 0
        self.cur_acc_value = 0
        self.packet_socket = packet_socket
        self.hw_interface = hw_interface
        self.display_args_glob = display_args_glob
        self.role = role
        self.event_sender = net.MaxFreqSender(self.packet_socket, 0.05) # should not be limiting
        self.acc_sender = net.MaxFreqSender(self.packet_socket, 1)
        self.gamestate = ClientGameState()
        if self.role == net.SPECTATOR:
            self.gamestate.client_ready = True
            self.gamestate.player_id = 42

    def send_event(self, event):
        if event == gg.TAP_LEFT:
            logging.info("sending left")
            self.event_sender.send(
                net.CLIENT_ACTION,
                self.gamestate.player_id,
                self.action_id,
                self.grid_id,
                net.LEFT)
        elif event == gg.TAP_RIGHT:
            logging.info("sending right")
            self.event_sender.send(
                net.CLIENT_ACTION,
                self.gamestate.player_id,
                self.action_id,
                self.grid_id,
                net.RIGHT)
        elif event == gg.TWO_FINGER_SWIPE:
            if self.gamestate.paused:
                logging.info("sending resume")
                self.event_sender.send(net.CLIENT_GAME_RESUME)
            else:
                logging.info("sending pause")
                self.event_sender.send(net.CLIENT_GAME_PAUSE)
        else:
            raise ValueError(event)
        self.action_id += 1

    def update_acc_value(self, new_acc_value):
        if new_acc_value != self.cur_acc_value:
            self.cur_acc_value = new_acc_value
            logging.info("cur_acc_value: %s", self.cur_acc_value)
            self.acc_sender.send(
                net.CLIENT_ANGLE,
                self.gamestate.player_id,
                self.cur_acc_value)

    def handle_packet(self, packet_type, payload):
        if packet_type == net.SERVER_GRID_STATE:
            flat_grid = payload
            self.gamestate.grid = utils.unflatten_grid(flat_grid, gg.M, gg.N)
            self.gamestate.round_running = True
            if self.role == net.SPECTATOR and not self.gamestate.game_started:
                self.gamestate.game_started = True
                self.gamestate.game_start_time = time.time()
        elif packet_type == net.SERVER_PLAYER_POSITIONS:
            (self.grid_id, *self.gamestate.players_xy) = payload
        elif packet_type == net.SERVER_ROUND_GAUGE_STATE:
            (self.gamestate.round_gauge_state,
             self.gamestate.round_gauge_speed) = payload
            self.gamestate.round_gauge_state_update_time = time.time()
        elif packet_type == net.SERVER_SCORE:
            self.gamestate.score, = payload
        elif packet_type == net.SERVER_GLOBAL_GAUGE_STATE:
            self.gamestate.global_gauge_state, = payload
        elif packet_type == net.SERVER_GAME_FINISHED:
            self.gamestate.game_finished = True
            # NB we will be killed by server closing connection
        elif packet_type == net.SERVER_GAME_PAUSE:
            self.gamestate.paused = True
        elif packet_type == net.SERVER_GAME_RESUME:
            self.gamestate.paused = False
        elif packet_type == net.SERVER_START_GAME:
            (self.gamestate.player_id, grid_size_m, grid_size_n) = payload
            self.gamestate.game_start_time = time.time()
            self.gamestate.game_started = True
            assert grid_size_m == gg.M
            assert grid_size_n == gg.N
        elif packet_type == net.SERVER_CONNECT:
            server_answer, = payload
            if server_answer != net.ACCEPTED:
                self.packet_socket.close()
                raise GameFinished()
            self.gamestate.connected = True
        elif packet_type == net.SERVER_END_ROUND:
            self.gamestate.round_running = False
            self.gamestate.round_outcome, = payload
        else:
            raise ValueError("Invalid packet type {}".format(packet_type))

    def handle_events(self):
        (quit, new_acc_value, self.gamestate.raw_acc_value_y,
         events) = self.hw_interface.get_events()
        if quit:
            self.packet_socket.close()
            raise GameFinished()
        elif not self.gamestate.connected:
            # wait for server's answer
            pass
        elif self.gamestate.game_started:
            for event in events:
                self.send_event(event)
            self.update_acc_value(new_acc_value)
        elif not self.gamestate.client_ready:
            if gg.TAP_RIGHT in events or gg.TAP_LEFT in events:
                self.gamestate.client_ready = True
                self.packet_socket.send(net.CLIENT_READY)
        else:
            # waiting for other players to be ready, don't do anything
            pass

    def handle_recv(self):
        for packet_type, payload in self.packet_socket.recv_all():
            self.handle_packet(packet_type, payload)

    def run(self):
        self.packet_socket.send(net.CLIENT_CONNECT, self.role)
        while True:
            self.handle_recv()
            if self.role != net.SPECTATOR:
                self.handle_events()
            time.sleep(0.02)
            self.display_args_glob[0] = copy.copy(self.gamestate)

