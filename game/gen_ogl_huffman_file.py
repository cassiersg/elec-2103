
import collections
import pickle
import opengl.cubes as cubes
import struct
import huffman
from huffman_generator import generate_huffman_decoder, generate_huffman_encoder

cubes.cubes_init()

# 'display_args.pkl' is generated by running client.py
# with opengl rendering and environment variable
# LOG_RENDER_ARGS=1
with open('display_args.pkl', 'rb') as f:
    v = pickle.load(f)

print('collecting images')
sequences = []
sequences_int = []
for (grid, players_xy, player_id, round_gauge, global_gauge, score) in v:
    grid = bytearray(x for y in grid for x in y)
    p1x, p1y, p2x, p2y = players_xy
    cubes.draw_cubes(grid, 7, 15, p1x, p1y, p2x, p2y, player_id, round_gauge)
    buf = bytearray(cubes.width*cubes.height*4)
    n_ints = cubes.cubes_export_chunks(buf, 32)
    sequences.extend(
        ((b, g, r, a), c) for b, g, r, a, c in
         struct.iter_unpack('=BBBBI', buf[:4*n_ints]))
    sequences_int.extend(struct.iter_unpack('=II', buf[:4*n_ints]))

# colors
print('generating color encoder/decoder')
_, (codes, tree) = huffman.encode([x for x, _ in sequences_int])
print('max color code length :', max(l for s, (s_c, i_c, l) in codes))
generate_huffman_encoder(codes, 'opengl/huffman_encode_colors.cpp')
generate_huffman_decoder(tree, 'opengl/huffman_decode_colors.cpp')

# lengths
print('generating length encoder/decoder')
_, (codes, tree) = huffman.encode([x for _, x in sequences_int])
print('max length code length :', max(l for s, (s_c, i_c, l) in codes))
generate_huffman_encoder(codes, 'opengl/huffman_encode_lengths.cpp')
generate_huffman_decoder(tree, 'opengl/huffman_decode_lengths.cpp')

