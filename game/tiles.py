
TILE_SIZE = 8
TILE_NB = 50
TILE_X = 100
TILE_Y = 60

BLACK = (  0,   0,   0)
GRAY  = (192, 192, 192)
WHITE = (255, 255, 255)
RED   = (255,   0,   0)
GREEN = (  0, 255,   0)
BLUE  = (  0,   0, 255)

colormap = [
    BLACK,
    WHITE,
    RED,
    GREEN,
    GRAY,
]
colormap.extend((256-len(colormap))*[BLACK])

tiles_image = TILE_NB * TILE_SIZE**2 * [0]

for i in range(64):
    for j in range(16):
        tiles_image[i+j*TILE_SIZE**2] = j

for j in range(8):
    for i in range(8*j):
        tiles_image[i+(j+16)*TILE_SIZE**2] = 3 # green
    for i in range(8*j, TILE_SIZE**2):
        tiles_image[i+(j+16)*TILE_SIZE**2] = 2 # red

for t in range(8):
    for j in range(8):
        for i in range(t):
            tiles_image[i+j*TILE_SIZE+(24+t)*TILE_SIZE**2] = 0 # black
        for i in range(t, TILE_SIZE):
            tiles_image[i+j*TILE_SIZE+(24+t)*TILE_SIZE**2] = 4 # gray

for t in range(8):
    for j in range(8):
        for i in range(t):
            tiles_image[i+j*TILE_SIZE+(32+t)*TILE_SIZE**2] = 4 # gray
        for i in range(t, TILE_SIZE):
            tiles_image[i+j*TILE_SIZE+(32+t)*TILE_SIZE**2] = 0 # black

