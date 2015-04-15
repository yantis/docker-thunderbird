#!/bin/bash

############################################################
#         Copyright (c) 2015 Jonathan Yantis               #
#          Released under the MIT license                  #
############################################################
#                                                          #
#
# If you want to try this out just use this script to launch
# and connect on an AWS EC2 instance.
#
# IMPORTANT: make sure to change the userdefined variables
#
# You must have aws cli installed.
# https://github.com/aws/aws-cli
#
# If using Arch Linux it is on the AUR as aws-cli
#
# This uses just basic Amazon Linux for simplicity.
# Amazon Linux AMI 2015.03.0 x86_64 HVM 
#
# Usage:
# aws-thunderbird.sh volumeid
#
# Example:
# aws-thunderbird.sh vol-f49d8ca2
#                                                          #
############################################################


############################################################

# USER DEFINABLE (NOT OPTIONAL)
KEYNAME=yantisec2 # Private key name
SUBNETID=subnet-d260adb7 # VPC Subnet ID
VOLUMEID=$2 # (this is your external volume to save your files to)

# USER DEFINABLE (OPTIONAL)
REGION=us-west-2
IMAGEID=ami-e7527ed7

# Exit the script if any statements returns a non true (0) value.
set -e

# Exit the script on any uninitialized variables.
set -u

# Exit the script if the user didn't specify at least one argument.
if [ "$#" -ne 1 ]; then
  echo "Error: You need to specifiy the volume id"
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
