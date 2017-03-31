import socket
import sys
import time
import pygame
import utils
import net

if utils.runs_on_rpi():
    import client_device as cd
else:
    import client_desktop as cd

from pygame.locals import *

from game_global import *
from game_frontend import *

if len(sys.argv) != 3:
    raise ValueError('Missing argument')

_, address, role = sys.argv

server_address = (address, 10000)

role = utils.PLAYER if role == 'player' else utils.SPECTATOR

# Create a TCP/IP socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as base_socket:
    # Connect to the server and send a CLIENT_CONNECT
    print("[CLIENT] Connecting to the server.")
    base_socket.connect(server_address)
    base_socket.setblocking(False)
    s = net.PacketSocket(base_socket)
    s.send(net.CLIENT_CONNECT, net.PLAYER)

    # Waiting for the SERVER_CONNECT answer
    print("[CLIENT] Waiting for server's response.")

    (packet_type, payload) = s.recv_block()

    if packet_type == utils.SERVER_CONNECT:
        (server_answer,) = payload
        if server_answer == utils.ACCEPTED:
            print("[CLIENT] Connection accepted by the server.")
        else:
            print("[CLIENT] Connection refused by the server.")
            print("[CLIENT] server answer:", server_answer)
            s.close()
            sys.exit()
    else:
        s.close()
        sys.exit()

    hw_interface = cd.HardwareInterface()

    print("[CLIENT] Advertising the server that we are ready.")
    s.send(net.CLIENT_READY)

    # Waiting for the SERVER_START_GAME message
    print("[CLIENT] Waiting for the start of the game.")
    (packet_type, payload) = s.recv_block()

    if packet_type == utils.SERVER_START_GAME:
        (player_id, grid_size_x, grid_size_y) = payload
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

    cur_acc_value = 0

    event_sender = net.MaxFreqSender(s, 0.05) # should not be limiting
    acc_sender = net.MaxFreqSender(s, 0.2)

    while True:
        time.sleep(0.01)
        (quit, new_acc_value, events) = hw_interface.get_events(cur_acc_value)

        if quit:
            pygame.quit()
            s.close()
            sys.exit()

        for event in events:
            if event == utils.LEFT:
                print("sending left")
                event_sender.send(net.CLIENT_ACTION, player_id, action_id, grid_id, utils.LEFT)
            elif event == utils.RIGHT:
                print("sending right")
                event_sender.send(net.CLIENT_ACTION, player_id, action_id, grid_id, utils.RIGHT)

            action_id += 1

        if new_acc_value != cur_acc_value:
            cur_acc_value = new_acc_value
            acc_sender.send(net.CLIENT_ANGLE, player_id, cur_acc_value)

        for packet_type, payload in s.recv_all():
            print("packet_type: {}, payload: {}".format(packet_type, payload))
            if packet_type == utils.SERVER_GRID_STATE:
                print("received server grid state")
                grid_id, *flat_grid = payload
                grid = utils.unflatten_grid(flat_grid, grid_size_x, grid_size_y)
            elif packet_type == utils.SERVER_ROUND_GAUGE_STATE:
                print("received server round gauge state")
                (round_gauge_state, gauge_speed) = payload
            elif packet_type == utils.SERVER_SCORE:
                print("received server score")
                (score,) = payload
            elif packet_type == utils.SERVER_GLOBAL_GAUGE_STATE:
                print("received server global gauge state")
                (global_gauge_state,) = payload
            elif packet_type == utils.SERVER_GAME_FINISHED:
                s.close()
                exit()
            else:
                ValueError("unknown packet type {}".format(packet_type))

        if grid is not None:
            hw_interface.update_display(grid, player_id, round_gauge_state,
                   global_gauge_state, score)
