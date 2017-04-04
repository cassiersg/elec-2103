import os
import pickle
import game_global as gg

SCALE_FACTOR = 4
TILES_ROW = 100

class TileRenderer:
    def __init__(self, hw_interface):
        self.hw_interface = hw_interface

    def display(self, *args):
        tiles = self._gen_tiles(*args)
        if 'EXPORT_GAME_TILES' in os.environ:
            export_tile_list(tiles)
        self.hw_interface.display_tiles(tiles)

    @staticmethod
    def _map_color(grid_id):
        if grid_id == gg.STRUCT:
            return 1
        elif grid_id == gg.WALL:
            return 4
        elif grid_id == gg.HOLE:
            return 0
        else:
            raise ValueError(str(grid_id))

    def _gen_tiles(self, grid, players_xy, player_id, round_gauge, global_gauge, score):
        tiles = 6000 * [0x00]
        for i in range(0, gg.M):
            for j in range(0, gg.N):
                for i_off in range(0, SCALE_FACTOR):
                    for j_off in range(0, SCALE_FACTOR):
                        color = self._map_color(grid[gg.N-j-1][i])
                        tiles[TILES_ROW*(j*SCALE_FACTOR+j_off)+i*SCALE_FACTOR+i_off] = color
        x1, y1, x2, y2 = players_xy
        if player_id == 1:
            c1, c2 = 2, 3
        elif player_id == 2:
            c1, c2 = 3, 2
        for i_off in range(0, SCALE_FACTOR):
            for j_off in range(0, SCALE_FACTOR):
                tiles[TILES_ROW*((gg.N-y1-1)*SCALE_FACTOR+j_off)+x1*SCALE_FACTOR+i_off] = c1
                tiles[TILES_ROW*((gg.N-y2-1)*SCALE_FACTOR+j_off)+x2*SCALE_FACTOR+i_off] = c2

        for j in range(0, SCALE_FACTOR*gg.N):
            for i_off in range(0, SCALE_FACTOR):
                if (SCALE_FACTOR*gg.N-j-1)/(SCALE_FACTOR*gg.N) > round_gauge/gg.GAUGE_STATE_INIT:
                    color = 3
                else:
                    color = 2
                tiles[TILES_ROW*j+(1+gg.M)*SCALE_FACTOR+i_off] = color
 
        return tiles


def export_tile_list(tiles):
    """For debug"""
    l = os.listdir('./tiles_lists')
    l.sort()
    n = int(l[-1][1:]) + 1
    fn = './tiles_lists/t{:03d}'.format(n)
    with open(fn, 'wb') as f:
        pickle.dump(tiles, f)
