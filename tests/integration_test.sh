#!/bin/bash

set -x

cd $(dirname $(readlink -f "$0"))

QUASSELCORE_PORT=4242

# wait for
#
wait_for_port() {

  echo "wait for quasselcore port ${QUASSELCORE_PORT}"

  # now wait for ssh port
  RETRY=40
  until [[ ${RETRY} -le 0 ]]
  do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/${QUASSELCORE_PORT}" 2> /dev/null
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 3s
      RETRY=$(expr ${RETRY} - 1)
    fi
  done

  if [[ $RETRY -le 0 ]]
  then
    echo "could not connect to the algernon instance"
    exit 1
  fi
}

send_request() {

  curl -I     http://localhost:${QUASSELCORE_PORT}
  curl -k -I  https://localhost:64080
}


inspect() {

  echo "inspect needed containers"
  for d in $(docker ps | tail -n +2 | awk '{print($1)}')
  do
    docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d}
  done
}

if [[ $(docker ps | tail -n +2 | egrep -c quassel) -eq 2 ]]
then
  inspect
  wait_for_port

  send_request

  exit 0
else
  echo "please run "
  echo " make start"
  echo "before"

  exit 1
fi


