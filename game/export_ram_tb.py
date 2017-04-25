
import opengl.cubes as cubes
import opengl.compression as compression
import struct
import pickle

import scene_draw



cubes.cubes_init()

with open('display_args.pkl', 'rb') as f:
    v = pickle.load(f)
v = [x for x in v if x is not None] # purge invalid gamestates

gamestate = v[0]
pixel_buf = scene_draw.render_gamestate(gamestate)
compressed_buf = bytearray(len(pixel_buf))
n_chunks, compressed_size = compression.chunk_compress_huffman(
    pixel_buf, compressed_buf)

ram = '\n'.join(
    hex(x)[2:] for x, in
    struct.iter_unpack('=I', compressed_buf[:4*compressed_size])
)
with open('../modelsim/ram_compressed.hex', 'w') as f:
    f.write(ram)

ram = '\n'.join(
    hex(x)[2:] for x, in
    struct.iter_unpack('=I', pixel_buf)
)
with open('../modelsim/ram_uncompressed.hex', 'w') as f:
    f.write(ram)

cubes.cubes_exit()

