#!/bin/bash

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

. $PRGDIR/env.sh
. $PRGDIR/printEnv.sh

# Public IP 
AWSSOCKS_IP=$(aws ec2 describe-instances  \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --no-cli-pager \
  --region $AWSSOCKS_REGION | sed s/\"//g) \

echo "AWSSOCKS_IP=$AWSSOCKS_IP"

unset AWSSOCKS_INSTANCE_ID
AWSSOCKS_INSTANCE_ID=$(aws ec2 describe-instances  --query 'Reservations[0].Instances[0].InstanceId' \
  --filters "Name=instance-state-name,Values=running,pending" \
  --no-cli-pager \
  --region $AWSSOCKS_REGION | sed s/\"//g) 

echo "AWSSOCKS_INSTANCE_ID=$AWSSOCKS_INSTANCE_ID"

while [ "null" != "$AWSSOCKS_INSTANCE_ID" ]
do
  echo "Terminating ..."
  aws ec2 terminate-instances \
     --instance-ids ${AWSSOCKS_INSTANCE_ID} \
     --no-cli-pager \
     --region $AWSSOCKS_REGION 

  unset AWSSOCKS_INSTANCE_ID
  AWSSOCKS_INSTANCE_ID=$(aws ec2 describe-instances  --query 'Reservations[0].Instances[0].InstanceId' \
    --filters "Name=instance-state-name,Values=running,pending"  \
    --no-cli-pager \
    --region $AWSSOCKS_REGION | sed s/\"//g) 

  echo "AWSSOCKS_INSTANCE_ID=$AWSSOCKS_INSTANCE_ID"

  sleep 2

done

. $PRGDIR/describeEC2Instances.sh


