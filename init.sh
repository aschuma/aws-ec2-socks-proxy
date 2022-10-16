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

. $PRGDIR/setAWSSOCKS_SECURITY_GROUP_ID.sh
. $PRGDIR/setAWSSOCKS_PUBLIC_KEY_NAME_EXISTS.sh

if [ ! -f ~/.ssh/${AWSSOCKS_KEY}.pub ]
then
  echo "SSH key ~/.ssh/${AWSSOCKS_KEY}.pub not available"  
  exit 1
else
  echo "Found SSH key ~/.ssh/${AWSSOCKS_KEY}.pub"  
fi

if [ -z "$AWSSOCKS_SECURITY_GROUP_ID" ]
then
  echo "Creating security group ..."  
  aws ec2 create-security-group \
    --group-name $AWSSOCKS_SECURITY_GROUP_NAME \
    --description "$AWSSOCKS_SECURITY_GROUP_NAME" \
    --region $AWSSOCKS_REGION \
    --no-cli-pager

  aws ec2 authorize-security-group-ingress \
    --group-name $AWSSOCKS_SECURITY_GROUP_NAME \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $AWSSOCKS_REGION \
    --no-cli-pager
fi

. $PRGDIR/setAWSSOCKS_SECURITY_GROUP_ID.sh
if [ -z "$AWSSOCKS_SECURITY_GROUP_ID" ]
then
  echo "Could not setup security group"  
  exit 1
fi 



if [ -z "$AWSSOCKS_PUBLIC_KEY_NAME_EXISTS" ]
then
  echo "Importing ssh key ..."  
  aws ec2 import-key-pair \
    --key-name ${AWSSOCKS_KEY_NAME} \
    --public-key-material fileb://~/.ssh/${AWSSOCKS_KEY}.pub \
    --region $AWSSOCKS_REGION \
    --no-cli-pager
fi

. $PRGDIR/setAWSSOCKS_PUBLIC_KEY_NAME_EXISTS.sh
if [ -z "$AWSSOCKS_PUBLIC_KEY_NAME_EXISTS" ]
then
  echo "Could not install public key"  
  exit 1
fi 

echo "
"  
read -n 1 -p "OK - press any Key"
