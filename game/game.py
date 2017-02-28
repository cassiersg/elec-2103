import readchar
from random import randint

# Constants
WALL = -1
EMPTY = 0
P1 = 1
P2 = 2

def build_grid(m, n):
    if m < 3 or n < 3:
        return None

    # Empty grid
    grid = [[EMPTY for i in range(m)] for j in range(n)]

    # Adding the floor
    grid[0][:] = [WALL for i in range(m)]

    # Adding players
    grid[1][0] = P1
    grid[1][m-1] = P2

    # List of possible ordered (from "left" to "right") possible positions
    positions = [(0,1), (1,1)]

    # Adding some random structures
    for i in range(2, m-2):
        length = randint(0, n-3)

        curr_x = i
        curr_y = 1

        positions_right = list()
        for j in range(length):
            # Avoid empty space of width one between two columns
            if grid[curr_y][curr_x-2] == WALL and grid[curr_y][curr_x-1] != WALL:
                break
            else:
                grid[curr_y][curr_x] = WALL

                if (curr_x, curr_y) in positions:
                    positions.remove((curr_x, curr_y))

                if grid[curr_y][curr_x-1] == EMPTY and (curr_x-1, curr_y) not in positions:
                    positions.append((curr_x-1, curr_y))

                if grid[curr_y][curr_x+1] == EMPTY and (curr_x+1, curr_y) not in positions:
                    positions_right.append((curr_x+1, curr_y))

            curr_y += 1

        if grid[curr_y][curr_x] == EMPTY and (curr_x, curr_y) not in positions:
            positions.append((curr_x, curr_y))

        positions_right.reverse()
        positions.extend(positions_right)

    if (m-2, 1) not in positions:
        positions.append((m-2, 1))

    positions.append((m-1, 1))

    return (grid, positions)

def print_grid(grid):
    m = len(grid)
    n = len(grid[0])

    for i in range(m):
        for j in range(n):
            if grid[m-i-1][j] == WALL:
                print(u"\u25A1", end=' ')
            elif grid[m-i-1][j] == P1:
                print(u"\u25A0", end=' ')
            elif grid[m-i-1][j] == P2:
                print(u"\u25A3", end=' ')
            else:
                print(" ", end=' '),

        print("")

def move_left(grid, player_id, player_pos, positions):
    (x, y) = positions[player_pos]

    if grid[y][x] != player_id or player_pos <= 0:
        return player_pos

    (x_next, y_next) = positions[player_pos-1]
    if grid[y_next][x_next] != EMPTY:
        return player_pos

    grid[y][x] = EMPTY
    grid[y_next][x_next] = player_id
    return player_pos-1

def move_right(grid, player_id, player_pos, positions):
    (x, y) = positions[player_pos]

    if grid[y][x] != player_id or player_pos >= len(positions) - 1:
        return player_pos

    (x_next, y_next) = positions[player_pos+1]
    if grid[y_next][x_next] != EMPTY:
        return player_pos

    grid[y][x] = EMPTY
    grid[y_next][x_next] = player_id
    return player_pos+1

def main():
    m = 10
    n = 5

    (grid, positions) = build_grid(m,n)
    print(positions)
    p1_pos = 0
    p2_pos = len(positions)-1

    print_grid(grid)

    key = ''
    while(key != '\x1b'):
        key = readchar.readchar()
        if key == 'q':
            p1_pos = move_left(grid, P1, p1_pos, positions)
        elif key == 'd':
            p1_pos = move_right(grid, P1, p1_pos, positions)
        elif key == '4':
            p2_pos = move_left(grid, P2, p2_pos, positions)
        elif key == '6':
            p2_pos = move_right(grid, P2, p2_pos, positions)

        print(chr(27) + "[2J")
        print_grid(grid)

if __name__ == "__main__":
    main()
