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
# config /etc/ansible/hosts
echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - config /etc/ansible/hosts."
getScript $SCRIPTS mk-ansible-hosts.sh
ANSIBLE=/etc/ansible/hosts
CSVS=$(ls | grep -E ".csv$")
if [ -n "$CSVS" ]; then
  for CSV in $CSVS; do
    GROUP=$CSV
    GROUP=${GROUP##*/}
    GROUP=${GROUP%.*}
    ./mk-ansible-hosts.sh -g $GROUP -i $(cat $CSV) -a $ANSIBLE -o
  done
fi
TMP_STR="master"
if $NODE_EXISTENCE; then
  TMP_STR+=",node"
fi
./mk-ansible-hosts.sh -g ${ANSIBLE_GROUP}:children -i ${TMP_STR} -a $ANSIBLE -o
echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - /etc/ansible/hosts configured."
echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - check connectivity amongst hosts ..."
getScript $SCRIPTS auto-cp-ssh-id.sh
getScript $SCRIPTS mk-ssh-conn.sh
getScript $SCRIPTS check-python.sh
if [[ -f ./passwd.log && -n "$(cat ./passwd.log)" ]]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - as ./passwd.log existed, automated make ssh connectivity."
  ./mk-ssh-conn.sh $(cat ./passwd.log)
  ./check-python.sh
fi
if ! ansible ${ANSIBLE_GROUP} -m ping; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - connectivity checking failed."
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - you should make ssh connectivity without password from this host to all the other hosts,"
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - and install python."
  echo "=== you can use the script mk-ssh-conn.sh in this directoryi, as:"
  echo "=== ./mk-ssh-conn.sh {PASSWORD}"
  exit 1
fi
if false; then
  while ! yes "\n" | ansible ${ANSIBLE_GROUP} -m ping; do
    echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - connectivity checking failed."
    echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - you should make ssh connectivity without password from this host to all the other hosts."
    # fix ssh 
    getScript $SCRIPTS auto-cp-ssh-id.sh
    getScript $SCRIPTS mk-ssh-conn.sh
    if [[ -f ./passwd.log && -n "$(cat ./passwd.log)" ]]; then
      echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - as ./passwd.log existed, automated make ssh connectivity."
      ./mk-ssh-conn.sh $(cat ./passwd.log)
      # fix python 
      for ip in $MASTER; do
        ssh -t -t root@$ip "if [ ! -x "$(command -v python)" ]; then if [ -x "$(command -v yum)" ]; then yum install -y python; fi; if [ -x "$(command -v apt-get)" ]; then apt-get install -y python; fi; fi "
      done
      if $NODE_EXISTENCE; then
        NODE=$(sed s/","/" "/g ./node.csv)
        for ip in $NODE; do
          ssh -t -t root@$ip "if [ ! -x "$(command -v python)" ]; then if [ -x "$(command -v yum)" ]; then yum install -y python; fi; if [ -x "$(command -v apt-get)" ]; then apt-get install -y python; fi; fi "
        done
      fi
    else
      echo "=== you can use the script mk-ssh-conn.sh in this directoryi, as:."
      echo "=== ./mk-ssh-conn.sh {PASSWORD}"
      exit 1
    fi
  done
fi
