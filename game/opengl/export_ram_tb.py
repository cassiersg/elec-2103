
import cubes
import struct

grid = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [3, 3, 0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 3, 3], [3, 3, 0, 0, 0, 3, 3, 3, 3, 4, 0, 0, 0, 3, 3], [3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 4, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]]
grid = bytearray(x for y in grid for x in y)

cubes.cubes_init()
cubes.draw_cubes(grid, 7, 15, 0, 1, 14, 1, 2, 20000)
buf = bytearray(cubes.width*cubes.height*4)
n_chunks, buf_size_used = cubes.cubes_export_compressed(buf, 32)
ram = '\n'.join(
    hex(x)[2:] for x, in
    struct.iter_unpack('=I', buf[:4*buf_size_used])
)
with open('../../modelsim/ram_compressed.hex', 'w') as f:
    f.write(ram)

cubes.cubes_image_export(buf)
ram = '\n'.join(
    hex(x)[2:] for x, in
    struct.iter_unpack('=I', buf)
)
with open('../../modelsim/ram_uncompressed.hex', 'w') as f:
    f.write(ram)



cubes.cubes_exit()

