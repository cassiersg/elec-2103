import random as r
import copy
import utils

import game_global as gg
import net

def init_round(m, n):
    """Initialize a new round.
    
    Returns
        - the grid, containing the wall, the structures, two holes and the two
        players
        - an ordered list of possible positions
        - the positions of the two holes
    """
    if m < 3 or n < 3:
        return None

    # Build the grid
    grid = [[gg.WALL for i in range(m)] for j in range(n)]

    # Add the floor
    grid[0][:] = [gg.STRUCT for i in range(m)]

    # List of possible positions ordered from "left" to "right"
    positions = [(0,1), (1,1)]

    # Adding some random structures on the grid
    for i in range(2, m-2):
        length = r.randint(0, n-3)

        curr_x = i
        curr_y = 1

        positions_right = list()
        for j in range(length):
            # Avoid empty space of width one between two columns
            if grid[curr_y][curr_x-2] == gg.STRUCT and grid[curr_y][curr_x-1] != gg.STRUCT:
                break
            else:
                grid[curr_y][curr_x] = gg.STRUCT

                if (curr_x, curr_y) in positions:
                    positions.remove((curr_x, curr_y))

                if grid[curr_y][curr_x-1] == gg.WALL and (curr_x-1, curr_y) not in positions:
                    positions.append((curr_x-1, curr_y))

                if grid[curr_y][curr_x+1] == gg.WALL and (curr_x+1, curr_y) not in positions:
                    positions_right.append((curr_x+1, curr_y))

            curr_y += 1

        if grid[curr_y][curr_x] == gg.WALL and (curr_x, curr_y) not in positions:
            positions.append((curr_x, curr_y))

        positions_right.reverse()
        positions.extend(positions_right)

    if (m-2, 1) not in positions:
        positions.append((m-2, 1))

    # Set two random holes in the grid, avoiding player's initial positions
    idx = list(range(1, len(positions)-1))
    r.shuffle(idx)
    holes = [positions[idx[0]], positions[idx[1]]]
    grid[holes[0][1]][holes[0][0]] = gg.HOLE
    grid[holes[1][1]][holes[1][0]] = gg.HOLE

    positions.append((m-1, 1))

    p1_pos = 0
    p2_pos = len(positions) - 1

    return (grid, positions, holes, p1_pos, p2_pos)


class GridState:
    def __init__(self, m, n):
        self.grid, self.positions, self.holes, p1_pos, p2_pos = init_round(m, n)
        self._player_pos = [p1_pos, p2_pos]

    def move(self, player_id, direction):
        if direction == net.LEFT:
            function = self.move_left
        elif direction == net.RIGHT:
            function = self.move_right
        else:
            raise ValueError(player_id)
        self._player_pos[player_id-1] = function(player_id)

    def get_player_pos(self, player_id):
        return self._player_pos[player_id-1]

    def is_winning(self):
        p1_pos, p2_pos = self._player_pos
        return set([self.positions[p1_pos], self.positions[p2_pos]]) == set(self.holes)

    @staticmethod
    def other_player(player_id):
        return 1 if player_id == 2 else 2

    def move_left(self, player_id):
        cur_player_pos = self.get_player_pos(player_id)
        (x, y) = self.positions[cur_player_pos]

        if cur_player_pos <= 0:
            return cur_player_pos

        (x_next, y_next) = self.positions[cur_player_pos-1]
        other_player_pos = self.get_player_pos(self.other_player(player_id))
        if (self.grid[y_next][x_next] not in [gg.WALL, gg.HOLE] or
            (x_next, y_next) == self.positions[other_player_pos]):
            return cur_player_pos

        return cur_player_pos-1

    def move_right(self, player_id):
        cur_player_pos = self.get_player_pos(player_id)
        (x, y) = self.positions[cur_player_pos]

        if cur_player_pos >= len(self.positions) - 1:
            return cur_player_pos

        (x_next, y_next) = self.positions[cur_player_pos+1]
        other_player_pos = self.get_player_pos(self.other_player(player_id))
        if (self.grid[y_next][x_next] not in [gg.WALL, gg.HOLE] or
            (x_next, y_next) == self.positions[other_player_pos]):
            return cur_player_pos

        return cur_player_pos+1

    def serialize_net(self):
        n_grid = copy.deepcopy(self.grid)
        x1, y1 = self.positions[self.get_player_pos(1)]
        x2, y2 = self.positions[self.get_player_pos(2)]
        return utils.flatten_grid(n_grid)

    def serialize_player_pos(self):
        x1, y1 = self.positions[self.get_player_pos(1)]
        x2, y2 = self.positions[self.get_player_pos(2)]
        return (x1, y1, x2, y2)



