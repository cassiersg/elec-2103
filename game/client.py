import socket
import sys
import time
import pygame

from pygame.locals import *
from utils import *

from game_global import *
from game_frontend import *

# Hardcoded server address
server_address = ('localhost', 10000)

# Create a TCP/IP socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to the server and send a CLIENT_CONNECT
print("Connecting to the server")
s.connect(server_address)
s.send(my_pack(CLIENT_CONNECT, [PLAYER]))

# Waiting for the SERVER_CONNECT answer
print("Waiting for server's response")
(_, packet_type, packet_length) = myrecv(s)
raw_payload = s.recv(packet_length)

if packet_type == SERVER_CONNECT:
    (server_answer,) = my_unpack(packet_type, raw_payload)
    if server_answer == ACCEPTED:
        print("Connection accepted by the server")
    else:
        print("Connection refused by the server")
        s.close()
        sys.exit()
else:
    s.close()
    sys.exit()

# PyGame init
screen = pygame_init()
myfont = pygame.font.SysFont("Comic Sans MS", 28)

# Advertising the server that we are ready with CLIENT_READY
print("Advertising the server that we are ready")
s.send(my_pack(CLIENT_READY, []))

# Waiting for the SERVER_START_GAME message
print("Waiting for the start of the game")
(_, packet_type, packet_length) = myrecv(s)
raw_payload = s.recv(packet_length)

if packet_type == SERVER_START_GAME:
    (player_id, grid_size_x, grid_size_y) = my_unpack(packet_type, raw_payload)
    print("Starting the game with player id " + str(player_id))
else:
    s.close()
    sys.exit()

grid_id = 0
action_id = player_id

s.settimeout(0.01)

while True:
    time.sleep(0.01)

    message = 0

    for event in pygame.event.get():
        if event.type == QUIT:
            pygame.quit()
            s.close()
            sys.exit()
        elif event.type == KEYDOWN:
            if event.key == pygame.K_k:
                print("Client sends left movement")
                s.send(my_pack(CLIENT_ACTION, [player_id, action_id, grid_id, LEFT]))
            elif event.key == pygame.K_m:
                print("Client sends right movement")
                s.send(my_pack(CLIENT_ACTION, [player_id, action_id, grid_id, RIGHT]))

            action_id += 2

    pygame.display.update()

    try:
        (_, packet_type, packet_length) = myrecv(s)
        raw_payload = s.recv(packet_length)
    except socket.timeout:
        continue

    if packet_type == SERVER_GRID_STATE:
        print("Received new grid state")
        unpacked_grid_state = my_unpack(SERVER_GRID_STATE, raw_payload)
        grid_id = unpacked_grid_state[0]
        flat_grid = unpacked_grid_state[1:]
        grid = unflatten_grid(flat_grid, grid_size_x, grid_size_y)
        draw_grid(screen, unflatten_grid(flat_grid, grid_size_x, grid_size_y))
    elif packet_type == SERVER_GAUGE_STATE:
        print("Received new gauge_status")
        (gauge_status,) = my_unpack(SERVER_GAUGE_STATE, raw_payload)
        draw_round_timer(screen, gauge_status)
    elif packet_type == SERVER_SCORE:
        (score,) = my_unpack(SERVER_SCORE, raw_payload)
        write_score(screen, myfont, score)
