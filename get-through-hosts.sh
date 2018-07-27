#!/bin/bash
show_help () {
cat << USAGE
usage: $0 [ -i HOST-IP ]

use to get through hosts.

    -i : Specify the IP address(es) of Host(s). If multiple, set the images in term of csv, 
         as 'host-ip-1,host-ip-2,host-ip-3'.

This script should run on a Master (to be) node.
USAGE
exit 0
}
# Get Opts
while getopts "hi:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    i)  HOSTS=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
[ -z "$*" ] && show_help
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -i $HOSTS
HOSTS=$(echo ${HOSTS} | tr "," " ")
# 0 set env
FILE=info.env
if [ -f ./$FILE ]; then
  source ./$FILE
else
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no environment file found!" 
  echo " - exit!"
  sleep 3
  exit 1
fi
getScript () {
  TRY=10
  URL=$1
  SCRIPT=$2
  for i in $(seq -s " " 1 ${TRY}); do
    curl -s -o ./$SCRIPT $URL/$SCRIPT
    if cat ./$SCRIPT | grep "^404: Not Found"; then
      rm -f ./$SCRIPT
    else
      break
    fi
  done
  if [ -f "./$SCRIPT" ]; then
    chmod +x ./$SCRIPT
  else
    echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - downloading failed !!!" 
    echo " - $URL/$SCRIPT"
    echo " - Please check !!!"
    sleep 3
    exit 1
  fi
}
PASSWD=$(cat ./passwd.log)
if [ -z "$PASSWD" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - need the password." 
fi
if [ ! -x "$(command -v expect)" ]; then
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update
    apt-get install -y tcl tk expect
  fi
  if [ -x "$(command -v yum)" ]; then
    yum makecache
    yum install -y tcl tk expect
  fi
fi
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
fi
getScript $SCRIPTS auto-cp-ssh-id.sh
if [[ -f ./passwd.log && -n "$(cat ./passwd.log)" ]]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - as ./passwd.log existed, automated make ssh connectivity."
  for HOST in $HOSTS; do
    if [ -n "$HOST" ]; then
      ./auto-cp-ssh-id.sh root $PASSWD $HOST
      ssh -t root@${HOST} "if [ ! -x "$(command -v python)" ]; then if [ -x "$(command -v yum)" ]; then yum install -y python; fi; if [ -x "$(command -v apt-get)" ]; then apt-get install -y python; fi; fi"
    fi
  done
fi
