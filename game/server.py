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

# Create a TCP/IP socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setblocking(0)

# Bind the socket to the port
server_address = ('localhost', 10000)
print('starting up on {} port {}'.format(*server_address), file=sys.stderr)
server.bind(server_address)

# Listen for incoming connections
server.listen(2)

# Sockets from which we expect to read
inputs = [server]

# Sockets to which we expect to write
outputs = []

# Outgoing message queues (socket:Queue)
message_queues = {}

# Number of connected client in players mode
players = 0
players_ready = 0
game_started = False

# Game state
(grid, positions, holes) = init_round(M, N)

p1_pos = 0
p2_pos = len(positions) - 1

speed_factor = 1.0

last_score_sent = -1
score = 0

last_grid_sent = -1
grid_id = 0

# Time managment
pygame.init()

game_start_time = pygame.time.get_ticks()
round_start_time = pygame.time.get_ticks()

game_elapsed_time = 0
round_elapsed_time = 0

last_iteration_start_time = pygame.time.get_ticks()
round_inc_elapsed_time = 0

round_gauge_state = 100
last_round_gauge_state_sent = -1

speed_factor = 1.0

while inputs:
    sleep(0.001)
    # Wait for at least one of the sockets to be ready for processing
    #print('waiting for the next event', file=sys.stderr)
    readable, writable, exceptional = select.select(inputs, outputs, inputs)

    for s in readable:
        if s is server:
            # A "readable" socket is ready to accept a connection
            connection, client_address = s.accept()
            print('\tconnection from', client_address, file=sys.stderr)
            connection.setblocking(0)
            inputs.append(connection)

            # Give the connection a queue for data we want to send
            message_queues[connection] = queue.Queue()
        else:
            header = myrecv(s)
            if header[0]:
                _, packet_type, packet_length = header
                raw_payload = s.recv(packet_length)

                # CLIENT CONNECT
                if packet_type == CLIENT_CONNECT:
                    (client_role,) = my_unpack(packet_type, raw_payload)
                    if client_role == PLAYER and players < 2:
                        players += 1
                        print("A player just connects")
                        message_queues[s].put(my_pack(SERVER_CONNECT, [ACCEPTED]))
                    elif client_role == PLAYER and players >= 2:
                        print("Too many players connected")
                        message_queues[s].put(my_pack(SERVER_CONNECT, [DENIED]))
                    else:
                        # Not supported currently
                        print("A spectator just connects")
                        message_queues[s].put(my_pack(SERVER_CONNECT, [DENIED]))
                # CLIENT READY
                elif packet_type == CLIENT_READY:
                    print("A client is ready to play")
                    players_ready += 1
                    message_queues[s].put(my_pack(SERVER_START_GAME,
                                                  [players_ready, M, N]))

                    if players_ready == 2:
                        print("Two players are ready")
                        game_started = True

                # CLIENT ACTION
                elif packet_type == CLIENT_ACTION:
                    print("Action received")
                    (player_id, action_id, player_grid_id, move_type) = my_unpack(CLIENT_ACTION,
                                                                           raw_payload)

                    if move_type == RIGHT:
                        if player_id == 1:
                            p1_pos = move_right(grid, player_id, p1_pos,
                                               positions, holes)
                        elif player_id == 2:
                            p2_pos = move_right(grid, player_id, p2_pos,
                                               positions, holes)
                    elif move_type == LEFT:
                        if player_id == 1:
                            p1_pos = move_left(grid, player_id, p1_pos,
                                               positions, holes)
                        elif player_id == 2:
                            p2_pos = move_left(grid, player_id, p2_pos,
                                               positions, holes)

                    grid_id += 1
                    print(grid_id)

                # Add output channel for response
                if s not in outputs:
                    print("Adding client to output list")
                    outputs.append(s)
            else:
                # Interpret empty result as closed connection
                print('\tclosing', client_address, file=sys.stderr)
                # Stop listening for input on the connection
                if s in outputs:
                    outputs.remove(s)

                inputs.remove(s)
                s.close()
                exit()

                # Remove message queue
                del message_queues[s]

    for s in writable:
        try:
            next_msg = message_queues[s].get_nowait()
        except queue.Empty:
            pass
            # No message waiting so stop checking for writability
            #print('\t', s.getpeername(), 'queue empty', file=sys.stderr)
            #outputs.remove(s)
        else:
            #print('\tsending {!r} to {}'.format(next_msg, s.getpeername()),
            #        file=sys.stderr)
            s.send(next_msg)

        # Send an updated grid if necessary
        if game_started:
            iteration_elapsed_time = pygame.time.get_ticks() - last_iteration_start_time
            last_iteration_start_time = pygame.time.get_ticks()
            round_elapsed_time = speed_factor*iteration_elapsed_time/1000 + round_elapsed_time
            round_gauge_state = round(((ROUND_TIMEOUT - round_elapsed_time)/ROUND_TIMEOUT)*100)

            game_elapsed_time = (pygame.time.get_ticks() - game_start_time)/1000
            remaining_game_time = GAME_TIMEOUT - game_elapsed_time

            if round_gauge_state != last_round_gauge_state_sent:
                print("Sending the gauge_status")
                if round_elapsed_time > ROUND_TIMEOUT:
                    if set([positions[p1_pos], positions[p2_pos]]) == set(holes):
                        score = score + 1
                    else:
                        game_start_time = pygame.time.get_ticks()
                        game_elapsed_time = 0

                        last_score_sent = -1
                        score = 0
                        last_grid_sent = -1
                        grid_id = 0

                    (grid, positions, holes) = init_round(M, N)
                    grid_id += 1
                    p1_pos = 0
                    p2_pos = len(positions) - 1

                    speed_factor = 1.0

                    last_round_gauge_state_sent = -1
                    round_start_time = pygame.time.get_ticks()
                    round_elapsed_time = 0
                    round_gauge_state = 100

                s.send(my_pack(SERVER_GAUGE_STATE, [round_gauge_state]))

                if s == writable[-1]:
                    last_round_gauge_state_sent = round_gauge_state

            if grid_id != last_grid_sent:
                print("Sending new grid")
                s.send(my_pack(SERVER_GRID_STATE, [grid_id] + flatten_grid(grid)))

                # If the updated grid was sent to everyone
                if s == writable[-1]:
                    last_grid_sent = grid_id

            if last_score_sent != score:
                s.send(my_pack(SERVER_SCORE, [score]))

                if s == writable[-1]:
                    last_score_sent = score

    # Handle "exceptional conditions"
    for s in exceptional:
        print('exception condition on', s.getpeername(), file=sys.stderr)
        # Stop listening for input on the connection
        inputs.remove(s)
        if s in outputs:
            outputs.remove(s)

        s.close()

        # Remove message queue
        del message_queues[s]

