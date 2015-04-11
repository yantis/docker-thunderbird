#!/bin/bash

############################################################
#         Copyright (c) 2015 Jonathan Yantis               #
#          Released under the MIT license                  #
############################################################
#                                                          #
# Connect to remote SSH server and and launch our container
# then reconnect to that container and run Thunderbird over
# X-forwarding. Then shut down the container when done.
#
# Usage:
# remote-thunderbird.sh username hostname
#
# Example:
# remote-thunderbird.sh user hermes
#                                                          #
############################################################

USER_NAME=$1
HOST_NAME=$2

# Pick a random port as we might have multiple things running.
PORT=$[ 32767 + $[ RANDOM % 32767 ] ]

# Connect to the server and launch our container.
ssh -o StrictHostKeyChecking=no \
    $USER_NAME@$HOST_NAME -tt << EOF
  sudo docker run \
    -d \
    -v /home/$USER_NAME/.ssh/authorized_keys:/authorized_keys:ro \
    -v /home/$USER_NAME/.thunderbird:/root/.thunderbird/ \
    -p $PORT:22 \
    yantis/thunderbird
  exit
EOF

# Now that is is launched go ahead and connect to our new server
# and politely kill root to force a container shutdown.
ssh -Y \
    -o ConnectionAttempts=255 \
    -o StrictHostKeyChecking=no \
     root@$HOST_NAME -p $PORT \
     -tt << EOF
  thunderbird
  sudo pkill -INT -u root
EOF
