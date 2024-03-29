
import os
import collections
import pickle
import struct
import copy
import itertools

import opengl.cubes as cubes
import opengl.chunker as chunker
import game_global as gg
import huffman
import scene_draw
import opengl.image_manip as image_manip
from huffman_generator import generate_huffman_decoder, generate_huffman_encoder
import client_core
import net

assert gg.M == cubes.m
assert gg.N == cubes.n

save_imgs = True # to save images generated for training as bmp

cubes.cubes_init()

# 'display_args.pkl' is generated by running client.py
# with opengl rendering and environment variable
# LOG_RENDER_ARGS=1
try:
    with open('display_args.pkl', 'rb') as f:
        v = pickle.load(f)
except IOError:
    print("cannot read 'display_args.pkl'.")
    print("maybe try to regenerate it, by running one client like")
    print("$ LOG_RENDER_ARGS=display_args.pkl python3 client.py localhost player")
    raise

## Add more variety in states
gs = client_core.ClientGameState()
v.append(gs)
gs = copy.copy(gs)
gs.connected = True
v.append(gs)
gs = copy.copy(gs)
gs.client_ready = True
v.append(gs)
gs = copy.copy(v[0])
gs.paused = True
v.append(gs)
gs = copy.copy(v[0])
gs.round_running = False
gs.round_outcome = net.WIN
gs.round_gauge_state = 0
v.append(gs)
gs = copy.copy(gs)
gs.round_outcome = net.LOOSE
v.append(gs)
gs = copy.copy(gs)
gs.game_finished = True
v.append(gs)

v = [x for x in v if x is not None] # purge invalid gamestates

print('collecting images')
sequences = []
sequences_int = []
for i, gamestate in enumerate(v):
    pixels = scene_draw.render_gamestate(gamestate)
    chunks = bytearray(len(pixels))
    n_ints = chunker.make_chunks(pixels, chunks)
    sequences.extend(
        ((b, g, r, a), c) for b, g, r, a, c in
         struct.iter_unpack('=BBBBI', chunks[:4*n_ints]))
    sequences_int.extend(struct.iter_unpack('=II', chunks[:4*n_ints]))
    if save_imgs:
        os.makedirs('training_images', exist_ok=True)
        image_manip.export_bmp_py(pixels, "training_images/img_gen_huffman_{:03d}.bmp".format(i).encode('ascii'))

colors = [c for c, _ in sequences_int]
# This makes all color appear at least onece, such
# that they are in the Huffman tree
colors.extend(0xff000000 | (r << 20) | (g << 12) | (b << 4) for r, g, b in itertools.product(range(0x10), range(0x10), range(0x10)))
lengths = [l for _, l in sequences_int]
# colors
print('generating color encoder/decoder')
_, (codes, tree) = huffman.encode(colors)
max_len_code_color = max(n_bits for sym, (code_str, code_int, n_bits) in codes)
print('max color code length:', max(l for s, (s_c, i_c, l) in codes))
generate_huffman_encoder(codes, 'opengl/huffman_encode_colors.cpp')
generate_huffman_decoder(tree, 'opengl/huffman_decode_colors.cpp')
generate_huffman_decoder(tree, '../src/huffman_decode_colors.sv', lang='sv')
avg_color = huffman.huffman_avg_len(colors)

# lengths
print('generating length encoder/decoder')
_, (codes, tree) = huffman.encode(lengths)
max_len_code_length = max(n_bits for sym, (code_str, code_int, n_bits) in codes)
assert max_len_code_length + max_len_code_color < 32
print('max length code length:', max(l for s, (s_c, i_c, l) in codes))
generate_huffman_encoder(codes, 'opengl/huffman_encode_lengths.cpp')
generate_huffman_decoder(tree, 'opengl/huffman_decode_lengths.cpp')
generate_huffman_decoder(tree, '../src/huffman_decode_lengths.sv', lang='sv')
avg_length = huffman.huffman_avg_len(lengths)
print('=== Training set performance ===')
chunks_per_frame = len(sequences_int)/len(v)
print('Average chunks per frame: {}'.format(int(chunks_per_frame)))
print('Average pixels per chunk: {:.3g}'.format(800*480/chunks_per_frame))
print('Color average bits: {:.3g}'.format(avg_color))
print('Chunk size average bits: {:.3g}'.format(avg_length))
print('Average bits per chunk: {:.3g}'.format(avg_color + avg_length))
print('Average kbits per frame: {:.3g}'.format((avg_color + avg_length)*chunks_per_frame/1000))

