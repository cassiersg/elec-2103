#!/bin/bash

cd ~/elec-2103-common/comm

while [ "$1" ]; do
    python3 server.py
done
