
import cubes
import compression
import struct
import pickle

def args2compressedbuf(v):
    (grid, players_xy, player_id, round_gauge, global_gauge, score) = v
    grid = bytearray(x for y in grid for x in y)
    p1x, p1y, p2x, p2y = players_xy
    cubes.draw_cubes(grid, cubes.n, cubes.m, p1x, p1y, p2x, p2y, player_id, round_gauge, 0xffffff)
    pixel_buf = bytearray(cubes.width*cubes.height*4)
    cubes.cubes_image_export(pixel_buf)
    compressed_buf = bytearray(len(pixel_buf))
    n_chunks, compressed_size = compression.chunk_compress_huffman(
        pixel_buf, compressed_buf, 32)
    return compressed_buf, compressed_size, n_chunks, pixel_buf

with open('../display_args.pkl', 'rb') as f:
    v = pickle.load(f)

grid = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3], [3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3], [3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]]
grid = bytearray(x for y in grid for x in y)

cubes.cubes_init()
#cubes.draw_cubes(grid, cubes.n, cubes.m, 0, 1, 14, 1, 2, 20000)
#pixel_buf = bytearray(cubes.width*cubes.height*4)
#cubes.cubes_image_export(pixel_buf)
#compressed_buf = bytearray(len(pixel_buf))
#n_chunks, compressed_size = compression.chunk_compress_huffman(
#    pixel_buf, compressed_buf, 32)
compressed_buf, compressed_size, n_chunks, pixel_buf = args2compressedbuf(v[2])
ram = '\n'.join(
    hex(x)[2:] for x, in
    struct.iter_unpack('=I', compressed_buf[:4*compressed_size])
)
with open('../../modelsim/ram_compressed.hex', 'w') as f:
    f.write(ram)

ram = '\n'.join(
    hex(x)[2:] for x, in
    struct.iter_unpack('=I', pixel_buf)
)
with open('../../modelsim/ram_uncompressed.hex', 'w') as f:
    f.write(ram)

cubes.cubes_exit()

