import select
import socket
import sys
import queue
import pygame

from time import sleep
from datetime import datetime
from utils import *
from game_global import *
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
    (grid, positions, holes, p1_pos, p2_pos) = init_round(M, N)

    last_score_sent = -1
    score = 0

    last_grid_sent = -1
    grid_id = 0

    round_start_time = pygame.time.get_ticks()
    last_iteration_start_time = round_start_time

    iteration_elapsed_time = 0

    round_gauge_state = GAUGE_STATE_INIT
    round_gauge_speed = ROUND_GAUGE_SPEED_INIT

    global_gauge_state = GAUGE_STATE_INIT
    global_gauge_speed = GLOBAL_GAUGE_SPEED

    # Client angles
    angles = [0, 0]

    ps = []
    glob_gauge_senders = []
    round_gauge_senders = []

    while True:
        # Wait, unless a client connects
        readable, *_ = select.select([server], [], [], 0.02)
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
                if packet_type == CLIENT_CONNECT:
                    client_role, = payload
                    if client_role == PLAYER and players < 2:
                        players += 1
                        print("[SERVER] A player just connects.")
                        s.send(SERVER_CONNECT, ACCEPTED)
                    elif client_role == PLAYER and players >= 2:
                        print("[SERVER] Too many players connected.")
                        s.send(SERVER_CONNECT, DENIED)
                        continue
                    else:
                        print("[SERVER] A spectator just connects.")
                        s.send(SERVER_CONNECT, ACCEPTED)
                elif packet_type == CLIENT_READY:
                    print("[SERVER] A client is ready to play.")
                    players_ready += 1
                    s.send(SERVER_START_GAME, players_ready, M, N)
                    if players_ready == 2:
                        print("[SERVER] Two clients are ready to play.")
                        game_started = True
                elif packet_type == CLIENT_ACTION:
                    print("[SERVER] Client action received.")
                    (player_id, action_id, player_grid_id, move_type) = payload
                    if move_type == RIGHT:
                        if player_id == 1:
                            p1_pos = move_right(grid, player_id, p1_pos, positions, holes)
                        elif player_id == 2:
                            p2_pos = move_right(grid, player_id, p2_pos, positions, holes)
                    elif move_type == LEFT:
                        if player_id == 1:
                            p1_pos = move_left(grid, player_id, p1_pos, positions, holes)
                        elif player_id == 2:
                            p2_pos = move_left(grid, player_id, p2_pos, positions, holes)
                    grid_id += 1
                elif packet_type == CLIENT_ANGLE:
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
                    s.send(SERVER_GAME_FINISHED)

                glob_gauge_s.send(SERVER_GLOBAL_GAUGE_STATE, round(global_gauge_state))

                if round_gauge_state <= 0:
                    if set([positions[p1_pos], positions[p2_pos]]) == set(holes):
                        score = score + 1
                    else:
                        last_score_sent = -1
                        score = 0
                        last_grid_sent = -1
                        grid_id = 0

                        global_gauge_state = GAUGE_STATE_INIT
                        global_gauge_speed = GLOBAL_GAUGE_SPEED

                    (grid, positions, holes, p1_pos, p2_pos) = init_round(M, N)
                    grid_id += 1

                    round_start_time = pygame.time.get_ticks()
                    last_iteration_start_time = round_start_time

                    round_gauge_state = GAUGE_STATE_INIT
                    round_gauge_speed = ROUND_GAUGE_SPEED_INIT

                round_gauge_s.send(SERVER_ROUND_GAUGE_STATE, round(round_gauge_state), round(round_gauge_speed))

                if grid_id != last_grid_sent:
                    print("[SERVER] Sending new grid")
                    s.send(SERVER_GRID_STATE, *([grid_id] + flatten_grid(grid)))

                    # If the updated grid was sent to everyone
                    if s == ps[-1]:
                        last_grid_sent = grid_id

                if last_score_sent != score:
                    s.send(SERVER_SCORE, score)

                    if s == ps[-1]:
                        last_score_sent = score

