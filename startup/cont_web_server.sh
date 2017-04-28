#!/bin/bash

cd ~/elec-2103/webcam

while [ "$1" ]; do
    python3 server.py
done
