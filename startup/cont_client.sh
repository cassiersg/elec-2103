#! /bin/bash

cd ~/elec-2103/game/

while [ "$1" ]; do
    python3 client.py 10.0.0.1 player
done
