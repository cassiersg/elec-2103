import socket
import sys
import time
import utils
import net
import threading
import opengl_rendering as rendering

if utils.runs_on_rpi():
    import client_device as cd
else:
    import client_desktop as cd

from game_global import *

display_args_glob = [None]

def update_display(renderer, display_args):
    if display_args[0] is None:
        return
    renderer.display(*display_args[0])

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

    hw_interface = cd.HardwareInterface()

    render_thread = threading.Thread(target=display_updater, args=(hw_interface, display_args_glob),daemon=True)
    render_thread.start()

    print("[CLIENT] Advertising the server that we are ready.")
    s.send(net.CLIENT_READY)

    # Waiting for the SERVER_START_GAME message
    print("[CLIENT] Waiting for the start of the game.")
    (packet_type, payload) = s.recv_block()

    if packet_type == net.SERVER_START_GAME:
        (player_id, grid_size_x, grid_size_y) = payload
        print("[CLIENT] Starting the game with player id " + str(player_id) + ".")
    else:
        print("[CLIENT] Didn't receive the SERVER START GAME message!",
              packet_type)
        sys.exit()

    grid = None
    score = 0
    round_gauge_state = GAUGE_STATE_INIT
    global_gauge_state = GAUGE_STATE_INIT
    grid_id = 0
    action_id = 0

    cur_acc_value = 0

    players_xy = None

    event_sender = net.MaxFreqSender(s, 0.05) # should not be limiting
    acc_sender = net.MaxFreqSender(s, 1)

    while True:
        time.sleep(0.01)
        (quit, new_acc_value, events) = hw_interface.get_events(cur_acc_value)

        if quit:
            s.close()
            sys.exit()

        for event in events:
            if event == net.LEFT:
                print("sending left")
                event_sender.send(net.CLIENT_ACTION, player_id, action_id, grid_id, net.LEFT)
            elif event == net.RIGHT:
                print("sending right")
                event_sender.send(net.CLIENT_ACTION, player_id, action_id, grid_id, net.RIGHT)
            elif event == net.PAUSE:
                print("sending pause")
                event_sender.send(net.CLIENT_GAME_PAUSE)
            elif event == net.RESUME:
                print("sending resume")
                event_sender.send(net.CLIENT_GAME_RESUME)

            action_id += 1

        if new_acc_value != cur_acc_value:
            cur_acc_value = new_acc_value
            acc_sender.send(net.CLIENT_ANGLE, player_id, cur_acc_value)

        for packet_type, payload in s.recv_all():
            #print("packet_type: {}, payload: {}".format(packet_type, payload))
            if packet_type == net.SERVER_GRID_STATE:
                #print("received server grid state")
                flat_grid = payload
                grid = utils.unflatten_grid(flat_grid, grid_size_x, grid_size_y)
            elif packet_type == net.SERVER_PLAYER_POSITIONS:
                #print("received server player positions")
                (positions_id, *players_xy) = payload
            elif packet_type == net.SERVER_ROUND_GAUGE_STATE:
                #print("received server round gauge state")
                (round_gauge_state, round_gauge_speed) = payload
                round_gauge_state_update_time = time.time()
            elif packet_type == net.SERVER_SCORE:
                #print("received server score")
                (score,) = payload
            elif packet_type == net.SERVER_GLOBAL_GAUGE_STATE:
                #print("received server global gauge state")
                (global_gauge_state,) = payload
            elif packet_type == net.SERVER_GAME_FINISHED:
                s.close()
                exit()
            elif packet_type == net.SERVER_GAME_PAUSE:
                hw_interface.paused = True
            elif packet_type == net.SERVER_GAME_RESUME:
                hw_interface.paused = False
            else:
                ValueError("unknown packet type {}".format(packet_type))

        if grid is not None and players_xy is not None:
            display_args_glob[0] = (
                    grid, players_xy,
                    player_id,
                    round_gauge_state,
                    global_gauge_state,
                    score,
                    round_gauge_speed,
                    round_gauge_state_update_time)

