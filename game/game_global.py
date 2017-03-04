# Grid elements
STRUCT  = 0
P1      = 1
P2      = 2
WALL    = 3
HOLE    = 4

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
