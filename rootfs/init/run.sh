#!/bin/sh

LISTEN=${LISTEN:-"0.0.0.0"}
LOGLEVEL=${LOGLEVEL:-"Info"}
PORT=${PORT:="4242"}
CONFIG_DIR=${QUASSELCORE_INSTALL_DIR}/data

QUASSELCORE_USER=${QUASSELCORE_USER:-quasselcore}
QUASSELCORE_PASSWORD=${QUASSELCORE_PASSWORD:-quasselcore}

export PATH=$PATH:${QUASSELCORE_INSTALL_DIR}/bin


#LDAP_HOSTNAME URI of the LDAP server - e.g. ldap://localhost or ldaps://localhost
#LDAP_PORT Port of the LDAP server.
#LDAP_BIND_DN Bind DN of the LDAP server.
#LDAP_BIND_PASSWORD Bind password for the bind DN of the LDAP server.
#LDAP_BASE_DN Search base DN of the LDAP server.
#LDAP_FILTER Search filter for user accounts on the LDAP server e.g. (objectClass=posixAccount)
#LDAP_UID_ATTR UID attribute to use for finding user accounts. e.g. uid

. /init/output.sh

# -------------------------------------------------------------------------------------------------

finish() {
  rv=$?
  [ ${rv} -gt 0 ] && echo -e "\033[38;5;202m\033[1mexit with signal '${rv}'\033[0m"
  exit $rv
}

trap finish SIGINT SIGTERM INT TERM EXIT

# -------------------------------------------------------------------------------------------------

stdbool() {

  if [ -z "$1" ]
  then
    echo "n"
  else
    echo ${1:0:1} | tr [A-Z] [a-z]
  fi
}


watch_and_kill() {
  sleep 5s
  killall -9 quasselcore
}

create_certificate() {

  # generate key
  if [ ! -f ${CONFIG_DIR}/quasselCert.pem ]
  then
    log_info "create certificate"

  #  openssl req \
  #    -x509 \
  #    -nodes \
  #    -days 365 \
  #    -newkey rsa:4096 \
  #    -keyout ${CONFIG_DIR}/quasselCert.pem \
  #    -out ${CONFIG_DIR}/quasselCert.pem \
  #    -subj "/CN=Quassel-core"

    openssl req \
      -x509 \
      -nodes \
      -days 365 \
      -newkey rsa:4096 \
      -keyout ${CONFIG_DIR}/quasselCert.key \
      -out ${CONFIG_DIR}/quasselCert.crt \
      -subj "/CN=Quassel-core" && \
    cat \
      ${CONFIG_DIR}/quasselCert.key \
      ${CONFIG_DIR}/quasselCert.crt \
      > ${CONFIG_DIR}/quasselCert.pem
  fi
}

create_database() {

  if [ ! -f  ${CONFIG_DIR}/quassel-storage.sqlite ]
  then
    log_info "create backend database"

    watch_and_kill &

    quasselcore \
      --configdir=${CONFIG_DIR} \
      --loglevel=Info \
      --select-backend=SQLite > /dev/null
  fi
}

config_ldap() {

  quasselcore-config --file data/quasselcore.conf

  quasselcore-config --file data/quasselcore.conf --dump
}

start_quasselcore() {

  # permissions
  chown -R quassel:quassel \
    ${CONFIG_DIR}

  command_args="
    --configdir=${CONFIG_DIR}
    --require-ssl
    --listen=${LISTEN}
    --loglevel=${LOGLEVEL}
    --port=${PORT}"

  if [ $(stdbool $DEV_QUASSEL_DEBUG) == "y" ]
  then
    command_args="${command_args} --debug"
  fi

  log_info "start quasselcore"

  quasselcore \
    ${command_args}
}

add_quasselcore_user() {

  if [ $(/init/manageusers.py list | wc -l) -eq 1 ]
  then
    log_info "add core user ${QUASSELCORE_USER}"

    /init/manageusers.py add \
      ${QUASSELCORE_USER} \
      ${QUASSELCORE_PASSWORD} > /dev/null
  fi


  /init/manageusers.py add \
      foofii \
      barbar
}


run() {

  create_certificate

  create_database

  config_ldap

  #add_quasselcore_user

  start_quasselcore
}

run
