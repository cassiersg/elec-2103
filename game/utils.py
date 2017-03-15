import socket

from enum import Enum
from struct import *

from game_global import *

# Packet types
CLIENT_CONNECT = 0
SERVER_CONNECT = 1
CLIENT_READY = 2
SERVER_START_GAME = 3
CLIENT_ACTION = 4
CLIENT_ANGLE = 5
SERVER_GAME_FINISHED = 6
SERVER_ACTION_RESPONSE = 7
SERVER_GRID_STATE = 8
SERVER_ROUND_GAUGE_STATE = 9
SERVER_SCORE = 10
SERVER_GLOBAL_GAUGE_STATE = 11

# Payload packing format
PACKET_FMT = {
    CLIENT_CONNECT: '!B',
    SERVER_CONNECT:'!B',
    SERVER_START_GAME: '!BBB',
    CLIENT_ACTION: '!BIIB',
    CLIENT_ANGLE: '!BB',
    SERVER_ACTION_RESPONSE: '!IB',
    SERVER_GRID_STATE: '!I' + str(M*N) + 'B',
    SERVER_ROUND_GAUGE_STATE: '!HH',
    SERVER_SCORE: '!I',
    SERVER_GLOBAL_GAUGE_STATE: '!H',
}

HEADER_FMT = '!BH'

# Client role
PLAYER = 0
SPECTATOR = 1

# Server accept status
ACCEPTED = 0
DENIED = 1

# Server action answer status
ACCEPTED = 0
REFUSED = 1

# Move types
LEFT = 0
RIGHT = 1

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
