
from time import sleep
import spidev
import struct
import datetime

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
        set_display(spi, 0)
        self.current_display = 0

    def pageflip(self):
        new_display = self.current_display ^ 0x1
        set_display(self.spi, new_display)
        self.current_display = new_display

    def draw_tiles(self, tiles_idx):
        assert len(tiles_idx) == 6000
        write_spi(self.spi, 0x10000, tiles_idx[:3000])
        write_spi(self.spi, 0x10000+3000, tiles_idx[3000:])

    def gen_tiles(self, grid, player_id, round_gauge, global_gauge):
        pass # see C file
    
    def update_display(self, *args):
        tiles = self.gen_tiles(*args)
        self.draw_tiles(tiles)
        self.pageflip()

