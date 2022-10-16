#!/bin/bash

# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`

echo "Base directory: $PRGDIR"

. $PRGDIR/env.sh
. $PRGDIR/printEnv.sh

echo "Pending..."
aws ec2 describe-instances \
   --region $AWSSOCKS_REGION \
   --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Status:State.Name,InstanceId:InstanceId}" \
   --no-cli-pager \
   --output text | grep pending

echo "Running..."
aws ec2 describe-instances \
   --region $AWSSOCKS_REGION \
   --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Status:State.Name,InstanceId:InstanceId}" \
   --no-cli-pager \
   --output text | grep running

AWSSOCKS_IP=$(aws ec2 describe-instances \
   --region $AWSSOCKS_REGION \
   --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Status:State.Name,InstanceId:InstanceId}" \
   --no-cli-pager \
   --output text | grep runnin  | awk '{print $2}')

echo "AWSSOCKS_IP:$AWSSOCKS_IP"

export AWSSOCKS_IP

