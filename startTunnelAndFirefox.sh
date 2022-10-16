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

AWSSOCKS_IP=""
while [ "" == "$AWSSOCKS_IP" ]
do
  sleep 2
  . $PRGDIR/setAWSSOCKS_IP.sh
done

read -n 1 -p "Start tunnel - press any Key"
nohup ssh -o "StrictHostKeyChecking no" -C -N  -i ~/.ssh/${AWSSOCKS_KEY}  ec2-user@${AWSSOCKS_IP} -D 4444 & 

nohup /Applications/Firefox.app/Contents/MacOS/firefox -proxy-server localhost:4444 &



