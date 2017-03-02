import game_global as gg

import random as r

'''
    Initialize a new round. This function returns
    - the grid, containing the wall, the structures, two holes and the two
    players
    - an ordered list of possible positions
    - the positions of the two holes
'''
def init_round(m, n):
    if m < 3 or n < 3:
        return None

    # Building the grid
    grid = [[gg.WALL for i in range(m)] for j in range(n)]

    # Adding the floor
    grid[0][:] = [gg.STRUCT for i in range(m)]

    # Adding players at the two extremites of the map
    grid[1][0] = gg.P1
    grid[1][m-1] = gg.P2

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

    return (grid, positions, holes)

def move_left(grid, player_id, player_pos, positions, holes):
    (x, y) = positions[player_pos]

    if grid[y][x] != player_id or player_pos <= 0:
        return player_pos

    (x_next, y_next) = positions[player_pos-1]
    if grid[y_next][x_next] not in [gg.WALL, gg.HOLE]:
        return player_pos

    grid[y][x] = gg.HOLE if (x, y) in holes else gg.WALL
    grid[y_next][x_next] = player_id
    return player_pos-1

def move_right(grid, player_id, player_pos, positions, holes):
    (x, y) = positions[player_pos]

    if grid[y][x] != player_id or player_pos >= len(positions) - 1:
        return player_pos

    (x_next, y_next) = positions[player_pos+1]
    if grid[y_next][x_next] not in [gg.WALL, gg.HOLE]:
        return player_pos

    grid[y][x] = gg.HOLE if (x, y) in holes else gg.WALL
    grid[y_next][x_next] = player_id
    return player_pos+1
