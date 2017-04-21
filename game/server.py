import socket

from time import sleep
from server_core import Server

# Create a TCP/IP socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
    server = Server(server_socket)

    while True:
        sleep(0.05)

        server.accept()

        server.process_clients_msgs()
        server.update_game_state()
        server.update_server_state()
