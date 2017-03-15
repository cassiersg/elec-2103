import socket
import sys
import time
import pygame
import client_desktop as cd

from pygame.locals import *
from utils import *

from game_global import *
from game_frontend import *

# Hardcoded server address
server_address = ('localhost', 10000)

role = PLAYER if sys.argv[1] == 'player' else SPECTATOR

# Create a TCP/IP socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    # Connect to the server and send a CLIENT_CONNECT
    print("[CLIENT] Connecting to the server.")
    s.connect(server_address)
    s.send(my_pack(CLIENT_CONNECT, [PLAYER]))

    # Waiting for the SERVER_CONNECT answer
    print("[CLIENT] Waiting for server's response.")
    (packet_type, packet_length) = myrecv(s)
    raw_payload = s.recv(packet_length)

    if packet_type == SERVER_CONNECT:
        (server_answer,) = my_unpack(packet_type, raw_payload)
        if server_answer == ACCEPTED:
            print("[CLIENT] Connection accepted by the server.")
        else:
            print("[CLIENT] Connection refused by the server.")
            s.close()
            sys.exit()
    else:
        s.close()
        sys.exit()

    # PyGame init
    screen = pygame_init()
    myfont = pygame.font.SysFont("Comic Sans MS", 28)

    # Advertising the server that we are ready with CLIENT_READY
    print("[CLIENT] Advertising the server that we are ready.")
    s.send(my_pack(CLIENT_READY, []))

    # Waiting for the SERVER_START_GAME message
    print("[CLIENT] Waiting for the start of the game.")
    (packet_type, packet_length) = myrecv(s)
    raw_payload = s.recv(packet_length)

    if packet_type == SERVER_START_GAME:
        (player_id, grid_size_x, grid_size_y) = my_unpack(packet_type, raw_payload)
        print("[CLIENT] Starting the game with player id " + str(player_id) + ".")
    else:
        s.close()
        sys.exit()

    grid = None
    score = 0
    round_gauge_state = GAUGE_STATE_INIT
    global_gauge_state = GAUGE_STATE_INIT
    grid_id = 0
    action_id = 0

    s.settimeout(0.01)

    cur_acc_value = 0

    while True:
        time.sleep(0.001)
        (quit, new_acc_value, events) = cd.get_events(cur_acc_value)

        if quit:
            pygame.quit()
            s.close()
            sys.exit()

        for event in events:
            if event == LEFT:
                s.send(my_pack(CLIENT_ACTION, [player_id, action_id, grid_id, LEFT]))
            elif event == RIGHT:
                s.send(my_pack(CLIENT_ACTION, [player_id, action_id, grid_id, RIGHT]))

            action_id += 1

        if new_acc_value != cur_acc_value:
            cur_acc_value = new_acc_value
            s.send(my_pack(CLIENT_ANGLE, [player_id, cur_acc_value]))

        header = myrecv(s)
        if header is not None:
            (packet_type, packet_length) = header
            raw_payload = s.recv(packet_length)
        else:
            continue

        if packet_type == SERVER_GRID_STATE:
            unpacked_grid_state = my_unpack(SERVER_GRID_STATE, raw_payload)
            grid_id = unpacked_grid_state[0]
            flat_grid = unpacked_grid_state[1:]
            grid = unflatten_grid(flat_grid, grid_size_x, grid_size_y)
        elif packet_type == SERVER_ROUND_GAUGE_STATE:
            (round_gauge_state, gauge_speed) = my_unpack(SERVER_ROUND_GAUGE_STATE, raw_payload)
        elif packet_type == SERVER_SCORE:
            (score,) = my_unpack(SERVER_SCORE, raw_payload)
        elif packet_type == SERVER_GLOBAL_GAUGE_STATE:
            (global_gauge_state,) = my_unpack(SERVER_GLOBAL_GAUGE_STATE, raw_payload)
        elif packet_type == SERVER_GAME_FINISHED:
            s.close()
            exit()

        if grid is not None:
            cd.refresh(screen, grid, player_id, round_gauge_state,
                   global_gauge_state, score)
