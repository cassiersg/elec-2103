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

def wait_display_ok(spi, display_id):
    """Wait for the pageflip"""
    # don't wait more than 100 ms, that means the given expected display_id is wrong
    for i in range(10):
        if bytes2int(read_spi(spi, 0x30000)) == display_id:
            return
        sleep(0.01)

class HardwareInterface:
    def __init__(self):
        self.spi = setup_spi()
        set_display(self.spi, 0)
        self.current_display = 0
        logging.info("initialized devHWinterface")

    def pageflip(self):
        new_display = self.current_display ^ 0x1
        set_display(self.spi, new_display)
        self.current_display = new_display

    def send_spi_buf(self, buf):
        t0 = time.time()
        assert(len(buf) <= 12000)
        idx = 0
        wait_display_ok(self.spi, self.current_display)
        t1 = time.time()
        while buf:
            sent_buf, buf = buf[:4000], buf[4000:]
            write_spi(self.spi, 0x10000 + idx, sent_buf)
            idx += 1000
        t2 = time.time()
        self.pageflip()
        t3 = time.time()

    def get_events(self):
        quit = False
        events = []

        touch = read_spi(self.spi, 0x02)
        if touch[3] == 1:
            events.append(gg.TAP_LEFT)
        elif touch[3] == 2:
            events.append(gg.TAP_RIGHT)
        elif touch[3] == 3:
            events.append(gg.TWO_FINGER_SWIPE)

        if events:
            write_spi(self.spi, 0x02, 4*[0x00])

        raw_acc_value_x, raw_acc_value_y, raw_acc_value_z  = struct.unpack('!iii', bytes(read_spi(self.spi, 0x03, 3)))
        logging.debug("acc_values: (%i, %i, %i)", raw_acc_value_x, raw_acc_value_y, raw_acc_value_z)
        cur_acc_value = min(255, abs(raw_acc_value_x))

        return (False, cur_acc_value, raw_acc_value_y, events)

