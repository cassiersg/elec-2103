import socket
import sys
import time
import threading
import _thread
import traceback

import utils
import net
import game_global as gg
import opengl_rendering as rendering
import client_core

if utils.runs_on_rpi():
    import client_device as cd
else:
    import client_desktop as cd

def update_display(renderer, display_args):
    if display_args[0] is None:
        return
    gamestate = display_args[0]
    renderer.display(gamestate)

def display_updater(hw_interface, display_args):
    try:
        renderer = rendering.Renderer(hw_interface)
        period = 0.02
        min_sleep_time = 0.0001
        while True:
            t0 = time.time()
            update_display(renderer, display_args)
            t = time.time()
            sl = period - (t-t0)
            time.sleep(max(min_sleep_time, sl))
    except:
        print(traceback.format_exc(), file=sys.stderr)
        _thread.interrupt_main()


def main():
    if len(sys.argv) != 3:
        raise ValueError('Missing argument')
    _, address, role = sys.argv
    server_address = (address, 10000)
    role = net.PLAYER if role == 'player' else net.SPECTATOR
    hw_interface = cd.HardwareInterface()
    display_args_glob = [None]
    render_thread = threading.Thread(
        target=display_updater,
        args=(hw_interface, display_args_glob),
        daemon=True)
    render_thread.start()
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as base_socket:
        base_socket.connect(server_address)
        base_socket.setblocking(False)
        s = net.PacketSocket(base_socket)
        client = client_core.Client(s, hw_interface, display_args_glob, role)
        client.run()

if __name__ == '__main__':
    utils.setup_log(logfile='client.log')
    main()
