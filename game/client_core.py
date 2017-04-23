import time
import copy

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
        self.game_started = False
        self.client_ready = False
        self.paused = False
        self.connected = False

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

    def send_event(self, event):
        if event == gg.TAP_LEFT:
            print("sending left")
            self.event_sender.send(
                net.CLIENT_ACTION,
                self.gamestate.player_id,
                self.action_id,
                self.grid_id,
                net.LEFT)
        elif event == gg.TAP_RIGHT:
            print("sending right")
            self.event_sender.send(
                net.CLIENT_ACTION,
                self.gamestate.player_id,
                self.action_id,
                self.grid_id,
                net.RIGHT)
        elif event == gg.TWO_FINGER_SWIPE:
            if self.gamestate.paused:
                print("sending resume")
                self.event_sender.send(net.CLIENT_GAME_RESUME)
            else:
                print("sending pause")
                self.event_sender.send(net.CLIENT_GAME_PAUSE)
        else:
            raise ValueError(event)
        self.action_id += 1

    def update_acc_value(self, new_acc_value):
        if new_acc_value != self.cur_acc_value:
            self.cur_acc_value = new_acc_value
            print("cur_acc_value", self.cur_acc_value)
            self.acc_sender.send(
                net.CLIENT_ANGLE,
                self.gamestate.player_id,
                self.cur_acc_value)

    def handle_packet(self, packet_type, payload):
        if packet_type == net.SERVER_GRID_STATE:
            flat_grid = payload
            self.gamestate.grid = utils.unflatten_grid(flat_grid, gg.M, gg.N)
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
            self.packet_socket.s.close()
            raise GameFinished() # TODO: class not yet defined
        elif packet_type == net.SERVER_GAME_PAUSE:
            self.gamestate.paused = True
        elif packet_type == net.SERVER_GAME_RESUME:
            self.gamestate.paused = False 
        elif packet_type == net.SERVER_START_GAME:
            (self.gamestate.player_id, grid_size_m, grid_size_n) = payload
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
            round_outcome, = payload
            if round_outcome == net.WIN:
                print("You won this round!")
            elif round_outcome == net.LOOSE:
                print("You lost this round!")
            else:
                raise ValueError("Invalid round outcome")
        else:
            raise ValueError("Invalid packet type {}".format(packet_type))

    def handle_events(self):
        (quit, new_acc_value, events) = self.hw_interface.get_events()
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
            if gg.TWO_FINGER_SWIPE in events:
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
            self.handle_events()
            time.sleep(0.02)
            self.display_args_glob[0] = copy.copy(self.gamestate)
