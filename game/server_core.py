import net
import select
import socket
import sys

from game import GameState
from game_global import M, N

class Client:
    # Client status, accepted here simply means that the server
    # socket has accepted the client socket
    (ACCEPTED, CONNECTED, READY, PLAYING) = (0, 1, 2, 3)

    # Undefined general constant
    UNDEFINED = -1

    def __init__(self, sock):
        self.socket = sock

        self.status = Client.ACCEPTED
        self.role = Client.UNDEFINED
        self.player_id = Client.UNDEFINED

class Server:
    # Server status
    WAIT_CLIENT_CONNECT = 0
    WAIT_CLIENT_READY = 1
    CLIENTS_READY = 2
    START_NEXT_ROUND = 3
    PLAYING = 4
    END_OF_ROUND = 5
    PAUSE = 6
    END_OF_GAME = 7

    def __init__(self, server_socket):
        print("[SERVER] Starting...")
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(('', 10000))
        server_socket.listen(2)
        self.server_socket = server_socket

        self.players_connected = 0
        self.players_ready = 0

        self.status = self.WAIT_CLIENT_CONNECT
        print("[SERVER] Current status: WAIT_CLIENT_CONNECT")
        self.status_before_pause = self.status

        self.need_send_positions = False
        self.positions_id = 0
        self.angles = [0, 0]

        self.clients = []
        self.glob_gauge_senders = []
        self.round_gauge_senders = []

        self.game_state = GameState()
        # Pause the game until it really starts to avoir that gauges starts
        # to diminish while the game hasn't yet started
        self.game_state.pause()

    def accept(self):
        readable, *_ = select.select([self.server_socket], [], [], 0.05)
        for s in readable:
            assert s is self.server_socket
            connection, client_address = self.server_socket.accept()
            print('[SERVER] New connection from', client_address)

            connection.setblocking(False)

            self.clients.append(Client(net.PacketSocket(connection)))
            self.glob_gauge_senders.append(net.MaxFreqSender(self.clients[-1].socket, 0.1))
            self.round_gauge_senders.append(net.MaxFreqSender(self.clients[-1].socket, 0.1))

    def process_clients_msgs(self):
        print("[SERVER] Processing client messages")
        for c in self.clients:
            for packet_type, payload in c.socket.recv_all():
                if packet_type == net.CLIENT_CONNECT:
                    self.handle_new_client(payload, c)
                elif packet_type == net.CLIENT_READY:
                    self.handle_ready_player(payload, c)
                elif packet_type == net.CLIENT_ACTION:
                    self.handle_action(payload, c)
                elif packet_type == net.CLIENT_ANGLE:
                    self.handle_angle(payload, c)
                elif packet_type == net.CLIENT_GAME_PAUSE:
                    self.pause(c)
                elif packet_type == net.CLIENT_GAME_RESUME:
                    self.resume(c)
                else:
                    print('[SERVER] Unknown packet type received', packet_type)

    def handle_new_client(self, payload, client):
        client_role, = payload

        response = net.ACCEPTED
        client.role = client_role

        if client_role == net.PLAYER:
            if self.status == Server.WAIT_CLIENT_CONNECT:
                print("[SERVER] A player just connects.")
                self.players_connected += 1
                if self.players_connected == 2:
                    print("[SERVER] Current status: WAIT_CLIENT_READY")
                    self.status = Server.WAIT_CLIENT_READY
            else:
                print("[SERVER] Too many players connected.")
                response = net.DENIED
                self.clients.remove(client)
        else:
            print("[SERVER] A spectator just connects.")

        client.socket.send(net.SERVER_CONNECT, response)

    def handle_ready_player(self, payload, client):
        if client.role != net.PLAYER:
            print("[SERVER] A non-player sends a ready message, I don't care")
            return

        print("[SERVER] A player is ready to play.")
        client.status = Client.READY
        self.players_ready += 1
        client.player_id = self.players_ready

        if self.players_ready == 2:
            print("[SERVER] Current status: CLIENTS_READY")
            self.status = Server.CLIENTS_READY
            self.start_game()

    def start_game(self):
        print("[SERVER] I am starting the game")
        for c in self.clients:
            if c.role == net.PLAYER:
                print("[SERVER] Sending start_game to player", c.player_id)
                c.socket.send(net.SERVER_START_GAME, c.player_id, M, N)
                c.status = Client.PLAYING
            else:
                print("[SERVER] Sending start_game to a spectator")
                # We don't care about player id for spectator
                c.socket.send(net.SERVER_START_GAME, 42, M, N)

        print("[SERVER] Current status: START_NEXT_ROUND")
        self.status = Server.START_NEXT_ROUND

        self.game_state.resume()

    def is_player_msg_valid(self, player_id, client):
        return (self.status == Server.PLAYING
                and client.role == net.PLAYER
                and client.status == Client.PLAYING
                and client.player_id == player_id)

    def handle_action(self, payload, client):
        print("[SERVER] I received an action from a client")

        (player_id, action_id, player_positions_id, move_type) = payload
        if not self.is_player_msg_valid(player_id, client):
            print("[SERVER] I received an invalid action")
            return

        #TODO: update move to return true if the position changed, false
        #otherwise (avoid to send useless positions updates)
        self.game_state.grid_state.move(player_id, move_type)
        self.positions_id += 1
        self.need_send_positions = True

    def handle_angle(self, payload, client):
        print("[SERVER] Client angle received.")

        (player_id, angle) = payload
        if not self.is_player_msg_valid(player_id, client):
            print("[SERVER] I received an invalid angle")
            return

        self.angles[player_id-1] = angle

    def update_game_state(self):
        if self.status == Server.PLAYING:
            self.game_state.update_speed_factor(self.angles)
            self.game_state.update_gauges_level()

            if self.game_state.is_game_finished():
                print("[SERVER] Current status: END_OF_GAME")
                self.status = Server.END_OF_GAME

            if self.game_state.is_round_finished():
                self.game_state.start_next_round()
                print("[SERVER] Current status: END_OF_ROUND")
                self.status = Server.END_OF_ROUND

                self.positions_id += 1
                return

    def update_server_state(self):
        if self.status == Server.START_NEXT_ROUND:
            self.send_grid()
            self.send_positions()
            self.send_score()
            self.send_global_gauge()
            self.send_round_gauge()

            print("[SERVER] Current status: PLAYING")
            self.status = Server.PLAYING
        elif self.status == Server.PLAYING:
            if self.need_send_positions:
                self.send_positions()
                self.need_send_positions = False

            self.send_global_gauge()
            self.send_round_gauge()
        elif self.status == Server.END_OF_ROUND:
            self.send_score()

            print("[SERVER] Current status: START_NEXT_ROUND")
            self.status = Server.START_NEXT_ROUND

    def send_global_gauge(self):
        print("[SERVER] Sending global gauges")
        for s in self.glob_gauge_senders:
            s.send(net.SERVER_GLOBAL_GAUGE_STATE, round(self.game_state.global_gauge_level))

    def send_round_gauge(self):
        print("[SERVER] Sending round gauges")
        for s in self.round_gauge_senders:
            s.send(net.SERVER_ROUND_GAUGE_STATE,
                   round(self.game_state.round_gauge_level),
                   round(self.game_state.round_gauge_speed))

    def send_positions(self):
        print("[SERVER] Sending new position list")
        for c in self.clients:
            s = c.socket
            s.send(net.SERVER_PLAYER_POSITIONS, self.positions_id,
                   *self.game_state.grid_state.serialize_player_pos())

    def send_score(self):
        print("[SERVER] Sending new score")
        for c in self.clients:
            s = c.socket
            s.send(net.SERVER_SCORE, self.game_state.score)

    def send_grid(self):
        print("[SERVER] Sending new grid")
        for c in self.clients:
            s = c.socket
            s.send(net.SERVER_GRID_STATE, *self.game_state.grid_state.serialize_net())

    def is_pause_resume_valid(self, client):
        return (client.role == net.PLAYER
                and client.status == Client.PLAYING)

    def pause(self, client):
        if not self.is_pause_resume_valid(client):
            print("[SERVER] Invalid pause command received")
            return

        print("[SERVER] Pausing the game")
        self.status_before_pause = self.status
        self.status = Server.PAUSE
        self.game_state.pause()

        for c in self.clients:
            s = c.socket
            s.send(net.SERVER_GAME_PAUSE)

    def resume(self, client):
        if not self.is_pause_resume_valid(client):
            print("[SERVER] Invalid pause command received")
            return

        print("[SERVER] Resuming the game")
        self.status = self.status_before_pause
        self.game_state.resume()

        for c in self.clients:
            s = c.socket
            s.send(net.SERVER_GAME_RESUME)
