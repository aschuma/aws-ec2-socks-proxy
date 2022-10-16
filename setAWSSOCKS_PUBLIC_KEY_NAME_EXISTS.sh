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

AWSSOCKS_PUBLIC_KEY_NAME_EXISTS=$(aws ec2 describe-key-pairs \
    --region $AWSSOCKS_REGION \
    --no-cli-pager | jq -r ".KeyPairs[] | select(.KeyName=\"proxy_public_key\") | .KeyName")

echo "AWSSOCKS_PUBLIC_KEY_NAME_EXISTS=$AWSSOCKS_PUBLIC_KEY_NAME_EXISTS"

export AWSSOCKS_PUBLIC_KEY_NAME_EXISTS

