
import cubes
import compression
import struct

grid = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3], [3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3], [3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]]
grid = bytearray(x for y in grid for x in y)

cubes.cubes_init()
cubes.draw_cubes(grid, 7, 15, 0, 1, 14, 1, 2, 20000)
pixel_buf = bytearray(cubes.width*cubes.height*4)
cubes.cubes_image_export(pixel_buf)
compressed_buf = bytearray(len(pixel_buf))
n_chunks, compressed_size = compression.chunk_compress_huffman(
    pixel_buf, compressed_buf, 32)
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

