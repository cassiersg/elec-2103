import time
import struct

import game_global

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
SERVER_PLAYER_POSITIONS = 9
SERVER_ROUND_GAUGE_STATE = 10
SERVER_SCORE = 11
SERVER_GLOBAL_GAUGE_STATE = 12

# Payload packing format
PACKET_FMT = {
    CLIENT_CONNECT: '!B',
    SERVER_CONNECT:'!B',
    CLIENT_READY: '!',
    SERVER_START_GAME: '!BBB',
    CLIENT_ACTION: '!BIIB',
    CLIENT_ANGLE: '!BB',
    SERVER_GAME_FINISHED: '!',
    SERVER_ACTION_RESPONSE: '!IB',
    SERVER_GRID_STATE:          '!' + str(game_global.M*game_global.N) + 'B',
    SERVER_PLAYER_POSITIONS:     '!IBBBB',
    SERVER_ROUND_GAUGE_STATE: '!HH',
    SERVER_SCORE: '!I',
    SERVER_GLOBAL_GAUGE_STATE: '!H',
}

HEADER_FMT = '!BH'
HEADER_LEN = 3

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

class ConnectionLost(Exception):
    pass

class PacketSocket:
    def __init__(self, socket):
        self.socket = socket
        self.buf = b''

    def read_socket(self):
        try:
            while True:
                b = self.socket.recv(4096)
                if not b:
                    raise ConnectionLost
                self.buf += b
        except OSError:
            pass

    def recv_one(self):
        self.read_socket()
        return self.parse_msg()

    def recv_all(self):
        self.read_socket()
        l = []
        while True:
            m = self.parse_msg()
            if m is None:
                return l
            l.append(m)

    def parse_msg(self):
        if len(self.buf) >= HEADER_LEN:
            packet_type, packet_len= struct.unpack(
                    HEADER_FMT, self.buf[:HEADER_LEN])
            if len(self.buf) >= HEADER_LEN + packet_len:
                payload = struct.unpack(
                        PACKET_FMT[packet_type],
                        self.buf[HEADER_LEN:HEADER_LEN+packet_len])
                self.buf = self.buf[HEADER_LEN+packet_len:]
                return (packet_type, payload)
            return None

    def format_packet(self, packet_type, payload):
        if payload:
            packed_payload = struct.pack(PACKET_FMT[packet_type], *payload)
        else:
            packed_payload = b''
        header = struct.pack(HEADER_FMT, packet_type, len(packed_payload))
        return header + packed_payload

    def send(self, packet_type, *payload):
        self.socket.sendall(self.format_packet(packet_type, payload))

    def recv_block(self, delay=0.01):
        while True:
            m = self.recv_one()
            if m is not None:
                return m
            time.sleep(delay)

class MaxFreqSender:
    def __init__(self, packet_socket, period):
        self.packet_socket = packet_socket
        self.period = period
        self.t_last = 0

    def send(self, *msg):
        t = time.time()
        if t > self.t_last + self.period:
            self.packet_socket.send(*msg)
            self.t_last = t
            return True
        else:
            return False
