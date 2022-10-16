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

AWSSOCKS_AMI=$(aws ec2 describe-images \
  --region $AWSSOCKS_REGION \
  --owners amazon \
  --filters 'Name=name,Values=amzn2-ami-hvm-2.0.????????.?-x86_64-gp2' 'Name=state,Values=available' \
  --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')
echo "AWSSOCKS_AMI=$AWSSOCKS_AMI"

if [ -z "$AWSSOCKS_AMI" ]
then
  echo "Could not find AMI"  
  exit 1
fi


echo " " 
read -n 1 -p "Start instance - press any Key"
aws ec2 run-instances \
  --region $AWSSOCKS_REGION \
  --image-id $AWSSOCKS_AMI \
  --security-group-ids $AWSSOCKS_SECURITY_GROUP_NAME \
  --instance-type ${AWSSOCKS_EC2_INSTANCE_SIZE} \
  --key-name ${AWSSOCKS_KEY_NAME} \
  --no-cli-pager \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=AWSSOCKS,Value=true}]'  

AWSSOCKS_INSTANCE_ID=$(aws ec2 describe-instances  --query 'Reservations[*].Instances[*].InstanceId' \
  --region $AWSSOCKS_REGION | sed s/\"//g)
echo "AWSSOCKS_INSTANCE_ID:$AWSSOCKS_INSTANCE_ID"

AWSSOCKS_IP=""
while [ "" == "$AWSSOCKS_IP" ]
do
  sleep 2
  . $PRGDIR/setAWSSOCKS_IP.sh
done

read -n 1 -p "END - press any Key"
