
"""
Usage:
$ python export_tiles_c.py > ../src/software/LELEC2103-SW/tiling_roms.h
"""
import tiles
import textwrap

def color2u32(c):
    r, g, b = c
    return (r << 16) + (g << 8) + b

def list2csource(l, name, array_type):
    return array_type + ' ' + name + '[] = {\n' + '\n'.join(
        textwrap.wrap(', '.join(str(x) for x in l))
    ) + '\n};'

def main():
    colormap = [color2u32(c) for c in tiles.colormap]
    colormap_string = list2csource(colormap, 'colormap_rom', 'int')
    tiles_image_string = list2csource(tiles.tiles_image, 'tiles_image_rom', 'char')
    output = textwrap.dedent('''
    #ifndef __H_TILING_ROMS_H_
    #define __H_TILING_ROMS_H_

    #define COLORMAP_ROM_LEN {}
    #define TILES_IMAGE_ROM_LEN {}

    {}
    {}

    #endif
    ''').format(
        len(colormap), len(tiles.tiles_image),
        colormap_string, tiles_image_string)
    print(output)

if __name__ == '__main__':
    main()
