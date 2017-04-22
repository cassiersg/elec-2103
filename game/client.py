import socket
import sys
import time
import utils
import net
import threading
import opengl_rendering as rendering
import copy

if utils.runs_on_rpi():
    import client_device as cd
else:
    import client_desktop as cd

import game_global as gg

class ClientGameState:
    def __init__(self, player_id):
        self.grid = None
        self.score = 0
        self.round_gauge_state = gg.GAUGE_STATE_INIT
        self.global_gauge_state = gg.GAUGE_STATE_INIT
        self.round_gauge_speed = 0
        self.round_gauge_state_update_time = time.time()
        self.players_xy = None
        self.player_id = player_id

class Client:
    def __init__(self, packet_socket, player_id):
        self.action_id = 0
        self.grid_id = 0
        self.event_sender = net.MaxFreqSender(s, 0.05) # should not be limiting
        self.acc_sender = net.MaxFreqSender(s, 1)
        self.cur_acc_value = 0
        self.gamestate = ClientGameState(player_id)
        self.packet_socket = packet_socket

    def handle_event(self, event):
        if event == net.LEFT:
            print("sending left")
            self.event_sender.send(
                net.CLIENT_ACTION,
                self.gamestate.player_id,
                self.action_id,
                self.grid_id,
                net.LEFT)
        elif event == net.RIGHT:
            print("sending right")
            self.event_sender.send(
                net.CLIENT_ACTION,
                self.gamestate.player_id,
                self.action_id,
                self.grid_id,
                net.RIGHT)
        elif event == net.PAUSE:
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
        elif packet_type == net.SERVER_END_ROUND:
            round_outcome, = payload
            if round_outcome == net.WIN:
                print("You won this round!")
            elif round_outcome == net.LOOSE:
                print("You lost this round!")
            else:
                raise ValueError("Invalid round outcome")
        else:
            raise ValueError("unknown packet type {}".format(packet_type))

display_args_glob = [None]

def update_display(renderer, display_args):
    if display_args[0] is None:
        return
    gs = display_args[0]
    if gs.grid is not None:
        renderer.display(gs.grid, gs.players_xy, gs.player_id, gs.round_gauge_state, gs.global_gauge_state, gs.score)

def display_updater(hw_interface, display_args):
    renderer = rendering.Renderer(hw_interface)
    period = 0.02
    min_sleep_time = 0.0001
    while True:
        t0 = time.time()
        update_display(renderer, display_args)
        t = time.time()
        sl = period - (t-t0)
        #print('sleep period', sl, 'dur', t-t0)
        time.sleep(max(min_sleep_time, sl))


if len(sys.argv) != 3:
    raise ValueError('Missing argument')

_, address, role = sys.argv

server_address = (address, 10000)

role = net.PLAYER if role == 'player' else net.SPECTATOR

last_render_time = time.time()

hw_interface = cd.HardwareInterface()

render_thread = threading.Thread(target=display_updater, args=(hw_interface, display_args_glob),daemon=True)
render_thread.start()
# Create a TCP/IP socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as base_socket:
    # Connect to the server and send a CLIENT_CONNECT
    print("[CLIENT] Connecting to the server.")
    base_socket.connect(server_address)
    base_socket.setblocking(False)
    s = net.PacketSocket(base_socket)
    s.send(net.CLIENT_CONNECT, role)

    # Waiting for the SERVER_CONNECT answer
    print("[CLIENT] Waiting for server's response.")

    (packet_type, payload) = s.recv_block()

    if packet_type == net.SERVER_CONNECT:
        (server_answer,) = payload
        if server_answer == net.ACCEPTED:
            print("[CLIENT] Connection accepted by the server.")
        else:
            print("[CLIENT] Connection refused by the server.")
            print("[CLIENT] server answer:", server_answer)
            s.close()
            sys.exit()
    else:
        s.close()
        sys.exit()


    print("[CLIENT] Advertising the server that we are ready.")
    s.send(net.CLIENT_READY)

    # Waiting for the SERVER_START_GAME message
    print("[CLIENT] Waiting for the start of the game.")
    (packet_type, payload) = s.recv_block()

    if packet_type == net.SERVER_START_GAME:
        (player_id, grid_size_x, grid_size_y) = payload
        assert grid_size_x == gg.M
        assert grid_size_y == gg.N
        print("[CLIENT] Starting the game with player id " + str(player_id) + ".")
    else:
        print("[CLIENT] Didn't receive the SERVER START GAME message!",
              packet_type)
        sys.exit()

    client = Client(s, player_id)

    while True:
        time.sleep(0.01)
        (quit, new_acc_value, events) = hw_interface.get_events(client.cur_acc_value)

        if quit:
            s.close()
            sys.exit()

        for event in events:
            client.handle_event(event)

        client.update_acc_value(new_acc_value)

        for packet_type, payload in s.recv_all():
            client.handle_packet(packet_type, payload)

        display_args_glob[0] = copy.copy(client.gamestate)

