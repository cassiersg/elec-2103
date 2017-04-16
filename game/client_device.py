import time
from time import sleep
import spidev
import struct
import datetime
import game_global as gg
import net
from utils import *

SCALE_FACTOR = 4
TILES_ROW = 100

def setup_spi():
    spi = spidev.SpiDev()
    spi.open(0,0)
    spi.max_speed_hz = 10000000
    return spi

def bytes2int(x):
    return struct.unpack('!i', bytes(x))[0]

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
    write_spi(spi, 0x30000, [0x00, 0x00, 0x00, display_id])
    while bytes2int(read_spi(spi, 0x30000)) != display_id:
        sleep(0.01)

class HardwareInterface:
    def __init__(self):
        self.spi = setup_spi()
        set_display(self.spi, 0)
        self.current_display = 0
        print("initialized devHWinterface")

    def pageflip(self):
        new_display = self.current_display ^ 0x1
        set_display(self.spi, new_display)
        self.current_display = new_display

    def send_spi_buf(self, buf):
        t0 = time.time()
        assert(len(buf) <= 12000)
        idx = 0
        t1 = time.time()
        while buf:
            sent_buf, buf = buf[:4000], buf[4000:]
            write_spi(self.spi, 0x10000 + idx, sent_buf)
            idx += 1000
        t2 = time.time()
        self.pageflip()
        t3 = time.time()
        #print('SPI: init', t1-t0, 'write', t2-t1, 'pageflip', t3-t2, 'n writes', idx//1000)

    def get_events(self, cur_acc_value):
        quit = False
        events = []

        touch = read_spi(self.spi, 0x02)
        if touch[3] == 1:
            events.append(net.LEFT)
        elif touch[3] == 2:
            events.append(net.RIGHT)

        if events:
            write_spi(self.spi, 0x02, 4*[0x00])
        
        raw_acc_value = bytes2int(read_spi(self.spi, 0x03))
        cur_acc_value = min(255, max(0, (raw_acc_value + 256) // 2))
        #print(raw_acc_value, cur_acc_value)

        return (False, cur_acc_value, events)

