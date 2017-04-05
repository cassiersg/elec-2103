import game_global as gg
from tiles import TILE_SIZE, TILE_X

SCALE_FACTOR = 4

class TileRenderer:
    def __init__(self, hw_interface):
        self.hw_interface = hw_interface

    def display(self, *args):
        tiles = self._gen_tiles(*args)
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

    def set_wall(self, tiles, grid, round_gauge):
        for x in range(TILE_X):
            for y in range(60):
                v = round(10 * TILE_SIZE * SCALE_FACTOR * round_gauge / gg.GAUGE_STATE_INIT)
                v2 = round(v / TILE_SIZE)
                try:
                    if x >= v2:
                        if (x-v2)//SCALE_FACTOR < gg.N and (x-v2+1)//SCALE_FACTOR >= gg.N:
                            tiles[y*TILE_X+x] = 32 + (TILE_SIZE - v % TILE_SIZE)
                        c1 = (grid[(x-v2+1)//SCALE_FACTOR][y//SCALE_FACTOR] == gg.WALL)
                        c2 = (grid[(x-v2)//SCALE_FACTOR][y//SCALE_FACTOR] == gg.WALL)
                        if c1 and c2:
                            c = self._map_color(gg.WALL)
                        elif c1:
                            c = 24 + (TILE_SIZE - v % TILE_SIZE)
                        elif c2:
                            c = 32 + (TILE_SIZE - v % TILE_SIZE)
                        else:
                            c = tiles[y*TILE_X+x]
                        tiles[y*TILE_X+x] = c
                except IndexError:
                    pass

    def _set_grid_case(self, tiles, grid_x, grid_y, color):
        for i_off in range(0, SCALE_FACTOR):
            for j_off in range(0, SCALE_FACTOR):
                tiles[TILE_X*(grid_x*SCALE_FACTOR+j_off)+grid_y*SCALE_FACTOR+i_off] = color

    def _gen_tiles(self, grid, players_xy, player_id, round_gauge, global_gauge, score):
        tiles = 6000 * [0x00]
        for i in range(0, gg.M):
            for j in range(0, gg.N):
                if grid[j][i] != gg.WALL:
                    color = self._map_color(grid[j][i])
                    self._set_grid_case(tiles, i, j, color)
        x1, y1, x2, y2 = players_xy
        if player_id == 1:
            c1, c2 = 2, 3
        elif player_id == 2:
            c1, c2 = 3, 2
        self.set_wall(tiles, grid,round_gauge)
        self._set_grid_case(tiles, x1, y1, c1)
        self._set_grid_case(tiles, x2, y2, c2)

        for j in range(0, SCALE_FACTOR*gg.N):
            tiles_gauge = SCALE_FACTOR*gg.N
            fill_level_tiles = tiles_gauge-j-1
            int_fill_level_asked = int(tiles_gauge*global_gauge//int(gg.GAUGE_STATE_INIT))
            if fill_level_tiles > int_fill_level_asked:
                color = 3
            elif fill_level_tiles < int_fill_level_asked:
                color = 2
            else:
                partial_fill_level = ((8*tiles_gauge*global_gauge)//int(gg.GAUGE_STATE_INIT)) - 8*int_fill_level_asked
                color = 16 + 7-partial_fill_level
            for i_off in range(0, SCALE_FACTOR):
                tiles[TILE_X*j+(1+gg.M)*SCALE_FACTOR+i_off] = color
 
        return tiles

