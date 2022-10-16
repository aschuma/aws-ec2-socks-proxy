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

echo "
All Instances..."
aws ec2 describe-instances \
   --region $AWSSOCKS_REGION \
   --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Name:Tags[?Key=='Name']|[0].Value,Type:InstanceType,Status:State.Name,VpcId:VpcId,InstanceId:InstanceId}" \
   --no-cli-pager \
   --output table

echo "
Running Instances..."
aws ec2 describe-instances \
   --region $AWSSOCKS_REGION \
   --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Name:Tags[?Key=='Name']|[0].Value,Type:InstanceType,Status:State.Name,VpcId:VpcId,InstanceId:InstanceId}" \
   --filters Name=instance-state-name,Values=running \
   --no-cli-pager \
   --output table

