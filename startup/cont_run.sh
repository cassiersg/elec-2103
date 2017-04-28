#!/bin/bash

HOSTNAME="$(hostname)"
echo "Running on $HOSTNAME"

cd ~/elec-2103/startup

if [ $HOSTNAME = "raspberrypi-g1-2" ]; then
    ./cont_client.sh
elif [ $HOSTNAME = "raspberrypi-g1-1" ]; then
    ./cont_server.sh &
    ./cont_web_server.sh
else
    echo "Not on a Raspberry Pi, why would you launch this script?"
fi
