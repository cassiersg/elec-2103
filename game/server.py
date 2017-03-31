import select
import socket
import sys
import queue
import pygame

from time import sleep
from datetime import datetime
from utils import *
import game_global
from game_global import *
import game_backend
from game_backend import *
import net

# Create a TCP/IP socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    #server.setblocking(0)

    # Bind the socket to the port
    server_address = ('', 10000)
    print('starting up on {} port {}'.format(*server_address), file=sys.stderr)
    server.bind(server_address)

    # Listen for incoming connections
    server.listen(2)

    # Number of connected client in players mode
    players = 0

    # Numbers of players who sent CLIENT READY
    players_ready = 0
    game_started = False

    # PyGame is used for time managment
    pygame.init()

    # Initialize the whole thing
    grid_state = game_backend.GridState(M, N)
    need_send_grid = True

    last_score_sent = -1
    score = 0

    last_positions_sent = -1
    positions_id = 0

    round_start_time = pygame.time.get_ticks()
    last_iteration_start_time = round_start_time

    iteration_elapsed_time = 0

    round_gauge_state = game_global.GAUGE_STATE_INIT
    round_gauge_speed = game_global.ROUND_GAUGE_SPEED_INIT

    global_gauge_state = game_global.GAUGE_STATE_INIT
    global_gauge_speed = game_global.GLOBAL_GAUGE_SPEED

    # Client angles
    angles = [0, 0]

    ps = []
    glob_gauge_senders = []
    round_gauge_senders = []

    while True:
        # Wait, unless a client connects
        readable, *_ = select.select([server], [], [], 0.05)
        for s in readable:
            assert s is server
            # A "readable" socket is ready to accept a connection
            connection, client_address = s.accept()
            print('[SERVER] Connection from', client_address, file=sys.stderr)
            connection.setblocking(0)
            ps.append(net.PacketSocket(connection))
            glob_gauge_senders.append(net.MaxFreqSender(ps[-1], 0.1)) # send at most 10 Hz
            round_gauge_senders.append(net.MaxFreqSender(ps[-1], 0.1)) # send at most 10 Hz

        # Read messages from clients
        for s in ps:
            for packet_type, payload in s.recv_all():
                if packet_type == net.CLIENT_CONNECT:
                    client_role, = payload
                    if client_role == net.PLAYER and players < 2:
                        players += 1
                        print("[SERVER] A player just connects.")
                        s.send(net.SERVER_CONNECT, net.ACCEPTED)
                    elif client_role == net.PLAYER and players >= 2:
                        print("[SERVER] Too many players connected.")
                        s.send(net.SERVER_CONNECT, net.DENIED)
                        continue
                    else:
                        print("[SERVER] A spectator just connects.")
                        s.send(net.SERVER_CONNECT, net.ACCEPTED)
                elif packet_type == net.CLIENT_READY:
                    print("[SERVER] A client is ready to play.")
                    players_ready += 1
                    s.send(net.SERVER_START_GAME, players_ready, M, N)
                    if players_ready == 2:
                        print("[SERVER] Two clients are ready to play.")
                        game_started = True
                elif packet_type == net.CLIENT_ACTION:
                    print("[SERVER] Client action received.")
                    (player_id, action_id, player_positions_id, move_type) = payload
                    grid_state.move(player_id, move_type)
                    positions_id += 1
                elif packet_type == net.CLIENT_ANGLE:
                    print("[SERVER] Client angle received.")
                    (player_id, angle) = payload
                    angles[player_id-1] = angle

        # Write messages to clients
        for s, glob_gauge_s, round_gauge_s in zip(ps, glob_gauge_senders, round_gauge_senders):
            # If the game has started already
            if game_started:
                iteration_elapsed_time = pygame.time.get_ticks() - last_iteration_start_time
                last_iteration_start_time = pygame.time.get_ticks()
                speed_factor = 1.0 + (sum(angles)/255.0)
                round_gauge_state -= speed_factor*round_gauge_speed*iteration_elapsed_time
                global_gauge_state -= global_gauge_speed*iteration_elapsed_time

                if global_gauge_state <= 0:
                    s.send(net.SERVER_GAME_FINISHED)

                glob_gauge_s.send(net.SERVER_GLOBAL_GAUGE_STATE, round(global_gauge_state))

                if round_gauge_state <= 0:
                    if grid_state.is_winning():
                        score = score + 1
                    else:
                        last_score_sent = -1
                        score = 0
                        last_positions_sent = -1
                        positions_id = 0

                        global_gauge_state = game_global.GAUGE_STATE_INIT
                        global_gauge_speed = game_global.GLOBAL_GAUGE_SPEED

                    grid_state = game_backend.GridState(M, N)
                    need_send_grid = True
                    positions_id += 1

                    round_start_time = pygame.time.get_ticks()
                    last_iteration_start_time = round_start_time

                    round_gauge_state = game_global.GAUGE_STATE_INIT
                    round_gauge_speed = game_global.ROUND_GAUGE_SPEED_INIT

                round_gauge_s.send(net.SERVER_ROUND_GAUGE_STATE, round(round_gauge_state), round(round_gauge_speed))

                if need_send_grid:
                    s.send(net.SERVER_GRID_STATE, *grid_state.serialize_net())
                    print("[SERVER] Sending new grid", repr(s))
                    if s == ps[-1]:
                        need_send_grid = False
 
                if positions_id != last_positions_sent:
                    print("[SERVER] Sending new position list")
                    s.send(net.SERVER_PLAYER_POSITIONS, positions_id, *grid_state.serialize_player_pos())

                    # If the updated position list was sent to everyone
                    if s == ps[-1]:
                        last_positions_sent = positions_id

                if last_score_sent != score:
                    s.send(net.SERVER_SCORE, score)

                    if s == ps[-1]:
                        last_score_sent = score

