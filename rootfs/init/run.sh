#!/bin/sh

LISTEN=${LISTEN:-"0.0.0.0"}
LOGLEVEL=${LOGLEVEL:-"Debug"}
PORT=${PORT:="4242"}

CONFIG_DIR=/var/lib/quassel

# generate key
if [ ! -f ${CONFIG_DIR}/quasselCert.pem ]
then
  openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:4096 \
    -keyout ${CONFIG_DIR}/quasselCert.pem \
    -out ${CONFIG_DIR}/quasselCert.pem \
    -subj "/CN=Quassel-core"


#  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout quasselCert.key -out quasselCert.crt && cat quasselCert.{key,crt} > quasselCert.pem
fi

if [ ! ${CONFIG_DIR}/quassel-storage.sqlite ]
then
  quasselcore \
    --configdir=${CONFIG_DIR}  \
    --select-backend=SQLite &

  killall quasselcore
else
  /usr/bin/manageusers.py list

fi


# permissions
#chown -R abc:abc \
#  ${CONFIG_DIR}

command_args="
  --configdir=${CONFIG_DIR}
  --require-ssl
  --select-backend=SQLite
  --listen=${LISTEN}
  --loglevel=${LOGLEVEL}
  --port=${PORT}
  --logfile=/dev/fd/1"

quasselcore \
  ${command_args}

