# Grid elements
STRUCT  = 0
WALL    = 1
HOLE    = 2
P1      = 3
P2      = 4

# Timeout (in ms)
ROUND_TIMEOUT = 6000.0
GLOBAL_TIMEOUT = 60000.0

# Gauges state and speed
# Gauge state is in gauge units
GAUGE_STATE_INIT = 65535.0
# Gauges speed are in gauge units per milliseconds
ROUND_GAUGE_SPEED_INIT = GAUGE_STATE_INIT/ROUND_TIMEOUT
GLOBAL_GAUGE_SPEED = GAUGE_STATE_INIT/GLOBAL_TIMEOUT

# Grid dimensions
M = 15
N = 7
