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

# Exit the script if any statements returns a non true (0) value.
set -e

# Exit the script on any uninitalized variables.
set -u

# Exit the script if the user didn't specify at least two arguments.
if [ "$#" -ne 2 ]; then
  echo "Error: You need to specifiy the host and user"
  exit 1
fi


# Create our new instance
ID=$(aws ec2 run-instances \
  --image-id ${IMAGEID} \
  --key-name ${KEYNAME} \
  --instance-type t2.micro \
  --region ${REGION} \
  --subnet-id ${SUBNETID} | \
  grep InstanceId | awk -F\" '{print $4}')

# Sleep 10 seconds here. Just to give it time to be created.
sleep 10
echo "Instance ID: $ID"


# Query every second until we get our IP.
while [ 1 ]; do
  IP=$(aws ec2 describe-instances --instance-ids $ID | \
    grep PublicIpAddress | \
    awk -F\" '{print $4}')

  if [ -n "$IP" ]; then
    echo "IP Address: $IP"
    break
  fi

  sleep 1
done

# Sleep 30 seconds here. To give it even more time for the instance
# to get to a "running state" so we can attach the volume properly.
sleep 30

# Attach our EBS volume here so we can save some stuff.
aws ec2 attach-volume \
  --instance-id $ID \
  --volume-id $VOLUMEID \
  --device /dev/xvdh

# Connect to the server and launch our container.
ssh -o ConnectionAttempts=255 \
  -o StrictHostKeyChecking=no \
  -i $HOME/.ssh/${KEYNAME}.pem\
  ec2-user@$IP -tt << EOF
sudo yum update -y
mkdir /home/ec2-user/external
sudo mount /dev/xvdh /home/ec2-user/external
mkdir /home/ec2-user/external/.thunderbird
sudo yum install docker -y
sudo service docker start
sudo docker run \
  -d \
  -v /home/ec2-user/.ssh/authorized_keys:/authorized_keys:ro \
  -v /home/ec2-user/external/.thunderbird:/root/.thunderbird/ \
  -p 49158:22 \
  yantis/thunderbird
exit
EOF

# Now that is is launched go ahead and connect to our new server
ssh -Y \
  -o ConnectionAttempts=255 \
  -o StrictHostKeyChecking=no \
  root@$IP -p 49158 \
  -t thunderbird

# Connect back to the server and unmount the volume.
# And initiate a shutdown while we are at it just because as a sanity check
# Also, make sure ec2-user is the owner.
ssh -o StrictHostKeyChecking=no \
  -i $HOME/.ssh/${KEYNAME}.pem\
  ec2-user@$IP -tt << EOF
sudo chgrp -R ec2-user /home/ec2-user/external
sudo chown -R ec2-user /home/ec2-user/external
sudo umount /dev/xvdh
sudo nohup shutdown 1 &
exit
EOF

# Detach our volume since we are done with it.
aws ec2 detach-volume \
  --instance-id $ID \
  --volume-id $VOLUMEID \
  --device /dev/xvdh

# Now that we are done. Delete the instance.
aws ec2 terminate-instances --instance-ids $ID

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
