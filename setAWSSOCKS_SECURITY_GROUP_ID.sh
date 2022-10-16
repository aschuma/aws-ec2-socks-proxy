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

AWSSOCKS_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --region=$AWSSOCKS_REGION | jq -r ".SecurityGroups[] | select(.GroupName==\"$AWSSOCKS_SECURITY_GROUP_NAME\") | .GroupId")

echo "AWSSOCKS_SECURITY_GROUP_ID=$AWSSOCKS_SECURITY_GROUP_ID"

export AWSSOCKS_SECURITY_GROUP_ID

