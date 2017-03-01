
from time import sleep
import spidev
import struct
import datetime
import game_global as gg

SCALE_FACTOR = 4
TILES_ROW = 100

def setup():
    spi = spidev.SpiDev()
    spi.open(0,0)
    spi.max_speed_hz = 10000000
    return spi

def bytes2int(x):
    if x[0] & 0x8:
        raise ValueError('Value transmitted over SPI not fitting in python int')
    return sum(y << (8*i) for (i, y) in enumerate(reversed(x)))

def int2bytes(x):
    return list(struct.pack('!I', x))

def int2bytes3(x):
    return int2bytes(x)[1:4]

def write_spi(spi, address, data):
    msg = [0x30] + int2bytes3(address) + [0x10] + int2bytes3(len(data)//4) + data
    spi.xfer2(msg)
    
def read_spi(spi, address, nb_words=1):
    msg = ([0x30] + int2bytes3(address)) + ([0x20] + int2bytes3(nb_words)) + 4*nb_words*[0x00]
    res = spi.xfer2(msg)
    return res[8:]

def set_display(spi, display_id):
    write_spi(spi, 0x0, [0x00, 0x00, 0x00, display_id])
    while bytes2int(read_spi(spi, 0x1)) != display_id:
        sleep(0.01)

class DeviceHwInterface:
    def __init__(self):
        self.spi = setup()
        set_display(self.spi, 0)
        self.current_display = 0

    def pageflip(self):
        new_display = self.current_display ^ 0x1
        set_display(self.spi, new_display)
        self.current_display = new_display

    def draw_tiles(self, tiles_idx):
        assert len(tiles_idx) == 6000
        write_spi(self.spi, 0x10000, tiles_idx[:3000])
        write_spi(self.spi, 0x10000+3000//4, tiles_idx[3000:])

    def map_color(self, grid_id, player_id):
        if grid_id == player_id:
            return 2
        elif grid_id == gg.P1 or grid_id == gg.P2:
            return 3
        elif grid_id == gg.STRUCT:
            return 1
        elif grid_id == gg.WALL:
            return 4
        elif grid_id == gg.HOLE:
            return 0
        else:
            raise ValueError(str(grid_id))

    def gen_tiles(self, grid, player_id, round_gauge, global_gauge, score):
        tiles = 6000 * [0x00]
        for i in range(0, gg.M):
            for j in range(0, gg.N):
                for i_off in range(0, SCALE_FACTOR):
                    for j_off in range(0, SCALE_FACTOR):
                        color = self.map_color(grid[gg.N-j-1][i], player_id)
                        tiles[TILES_ROW*(j*SCALE_FACTOR+j_off)+i*SCALE_FACTOR+i_off] = color
        return tiles
 
    def update_display(self, *args):
        tiles = self.gen_tiles(*args)
        self.draw_tiles(tiles)
        self.pageflip()

    def get_events(self, cur_acc_value):
        return (False, cur_acc_value, [])

