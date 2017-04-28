#!/bin/bash

HOSTNAME="$(hostname)"
echo "Running on $HOSTNAME"

cd ~/elec-2103/startup

if [ $HOSTNAME = "raspberrypi-g1-2" ]; then
    echo "Launching continuous client"
    ./cont_client.sh
elif [ $HOSTNAME = "raspberrypi-g1-1" ]; then
    echo "Launching continuous game server"
    ./cont_server.sh &
    echo "Launching continuous web server"
    ./cont_web_server.sh
else
    echo "Not on a Raspberry Pi, why would you launch this script?"
fi
