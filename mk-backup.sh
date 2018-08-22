#!/bin/bash
FILE=info.env
if [ -f ./$FILE ]; then
  source ./$FILE
else
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no environment file found!" 
  echo " - exit!"
  sleep 3
  exit 1
fi
BAK=/var/k8s/bak
NOW=$(date -d today +'%Y-%m-%d-%H:%M:%S')
ansible ${MASTER_GROUP} -m shell -a "if [ -d "${BAK}" ]; then mv $BAK ${BAK}-${NOW}; else echo ' - no previous backup found.'; fi"
ansible ${MASTER_GROUP} -m shell -a "mkdir -p $BAK"
#THIS_DIR=$(cd "$(dirname "$0")";pwd)
TMP=/tmp/k8s/bak
[ -d "$TMP" ] && rm -rf $TMP
mkdir -p $TMP
cp ./*.csv ./info.env passwd.log $TMP
ansible ${MASTER_GROUP} -m copy -a "src=${TMP}/ dest=${BAK}"
