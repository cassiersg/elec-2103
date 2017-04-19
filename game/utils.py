import socket

from enum import Enum
from struct import *

from game_global import *


# SOON DEPRECATED
def myrecv(s):
    try:
        header = s.recv(3)
    except (socket.timeout, ) as e:
        return None
    else:
        if len(header) == 3:
            (packet_type, packet_length) = unpack(HEADER_FMT, header)
            return (packet_type, packet_length)
        else:
            return None

def get_next_header(s):
    expected_len = 3

    try:
        header = s.recv(expected_len)
    except socket.timeout as e:
        return None
    else:
        received_len = len(header)
        while received_len < expected_len:
            header += s.recv(expected_len-received_len)
            received_len = len(header)

        (packet_type, packet_length) = unpack(HEADER_FMT, header)
        return (packet_type, packet_length)

def get_next_payload(s, packet_len):
    expected_len = packet_len

    try:
        payload = s.recv(expected_len)
    except socket.timeout as e:
        return None
    else:
        received_len = len(payload)
        while received_len < expected_len:
            payload += s.recv(expected_len-received_len)
            received_len = len(payload)

        return payload

def flatten_grid(grid):
    return [item for sublist in grid for item in sublist]

def unflatten_grid(flat_grid, n, m):
    return [[flat_grid[i+j*n] for i in range(n)] for j in range(m)]

def my_unpack(packet_type, raw_payload):
    return unpack(PACKET_FMT[packet_type], raw_payload)

def my_pack(packet_type, payload):
    if len(payload) > 0:
        packed_payload = pack(PACKET_FMT[packet_type], *payload)
    else:
        packed_payload = b''

    packed_header = pack(HEADER_FMT, packet_type, len(packed_payload))

    return packed_header + packed_payload

is_rpi = 'raspberry' in socket.gethostname()
def runs_on_rpi():
    return is_rpi

