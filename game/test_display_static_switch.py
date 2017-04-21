from time import sleep
import spidev
import struct
import datetime
import game_global as gg
import net
from utils import *

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


def send_spi_buf(spi, buf):
    idx = 0
    step = 4000
    while buf:
        sent_buf, buf = buf[:step], buf[step:]
        write_spi(spi, 0x10000+idx, sent_buf)
        idx += step//4

with open('compressed.raw', 'rb') as f:
    c = f.read()


import opengl.cubes as cubes
import opengl.compression as compression
import struct
import pickle

def args2compressedbuf(v):
    (grid, players_xy, player_id, round_gauge, global_gauge, score) = v
    grid = bytearray(x for y in grid for x in y)
    p1x, p1y, p2x, p2y = players_xy
    cubes.draw_cubes(grid, gg.N, gg.M, p1x, p1y, p2x, p2y, player_id, round_gauge)
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    cubes.cubes_image_export(pixel_buf)
    compressed_buf = bytearray(len(pixel_buf))
    n_chunks, compressed_size = compression.chunk_compress_huffman(
        pixel_buf, compressed_buf, 32)
    return compressed_buf, compressed_size, n_chunks

with open('display_args.pkl', 'rb') as f:
    v = pickle.load(f)

grid = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3], [3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3], [3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]]
grid = bytearray(x for y in grid for x in y)

cubes.cubes_init()
#cubes.draw_cubes(grid, gg.N, gg.M, 0, 1, 14, 1, 2, 20000)
#pixel_buf = bytearray(cubes.width*cubes.height*4)
#cubes.cubes_image_export(pixel_buf)
#compressed_buf = bytearray(len(pixel_buf))
#n_chunks, compressed_size = compression.chunk_compress_huffman(
#    pixel_buf, compressed_buf, 32)
#c1, _ = args2compressedbuf(v[0])
#c2, _ = args2compressedbuf(v[1])


#for i in range(len(compressed_buf)):
#    compressed_buf[i] = (i // 256) % 256

#c = compressed_buf[:12000]
spi = setup_spi()
cd = 0
set_display(spi, 0)
cl = [args2compressedbuf(x) for x in v]
for i, (c, size, n_chunks) in enumerate(cl[3:10]):
    print(i)
    print(size, n_chunks)
    #sleep(0.1)
    print("s")
    #set_display(spi, 1)
    send_spi_buf(spi, list(c[:12000]))
    set_display(spi, cd)
    cd = cd ^ 0x1
    print(i)
    read = read_spi(spi, 0x10000, 25)
    if list(c[:len(read)]) == read:
        print('ok')
    else:
        print('different')
    read1 = read_spi(spi, 0x10000, 300)
    read2 = [] #read_spi(spi, 0x10000+1000, size - 1001)
    read = read1 + read2
    if list(c[:len(read)]) == read:
        print('ok')
    else:
        print('different')
        cread = list(c[:len(read)])
        for i in range(len(read)):
            if read[i] != cread[i]:
                print(i, read[i], cread[i])
    #pix_buf = bytearray(cubes.width*cubes.height*4)
    #compression.chunk_decompress_huffman(bytearray(read), pix_buf, n_chunks)
    #compression.export_bmp_py(pix_buf)
    #sleep(0.1)
    sleep(0.8)


while True:
    sleep(0.5)
    set_display(spi, cd)
    cd  = cd ^ 0x1
    print('pageflip', cd)

#for i in range(0):
#    print(i, ':', end=' ')
#    for j in range(40):
#        print(c[i*40+j], end=' ')
#    print()
cubes.cubes_exit()
