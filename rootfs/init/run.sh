#!/bin/sh

QUASSELCORE_LISTEN=${QUASSELCORE_LISTEN:-"0.0.0.0"}
QUASSELCORE_LOGLEVEL=${QUASSELCORE_LOGLEVEL:-"Info"}
QUASSELCORE_PORT=${QUASSELCORE_PORT:="4242"}
QUASSELCORE_CONFIG_DIR=${QUASSELCORE_INSTALL_DIR}/data

QUASSELCORE_USER=${QUASSELCORE_USER:-quasselcore}
QUASSELCORE_PASSWORD=${QUASSELCORE_PASSWORD:-quasselcore}

export PATH=$PATH:${QUASSELCORE_INSTALL_DIR}/bin

[ -d "${QUASSELCORE_CONFIG_DIR}" ] || mkdir -vp "${QUASSELCORE_CONFIG_DIR}"


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
  [ ${rv} -gt 0 ] && log_INFO "exit with signal '${rv}'"
  exit $rv
}

trap finish SIGINT SIGTERM INT TERM EXIT

# -------------------------------------------------------------------------------------------------

stdbool() {

  if [ -z "$1" ]
  then
    echo "n"
  else
    echo "${1:0:1}" | tr '[:upper:]' '[:lower:]'
  fi
}

check_data_directory() {

  if [ "$(whoami)" != "$(stat -c %G "${QUASSELCORE_CONFIG_DIR}")" ]
  then
    log_error "wrong permissions for data directory."
    log_error "the quassel user can't write into ${QUASSELCORE_CONFIG_DIR}."

    exit 1
  fi

  [ -d "${QUASSELCORE_INSTALL_DIR}/.config/quassel-irc.org" ] || mkdir -vp "${QUASSELCORE_INSTALL_DIR}/.config/quassel-irc.org"

#  stat -c %G ${QUASSELCORE_CONFIG_DIR}
#  stat -c %A ${QUASSELCORE_CONFIG_DIR}
#  stat -c %a ${QUASSELCORE_CONFIG_DIR}

  set -e
  touch "${QUASSELCORE_CONFIG_DIR}/.keep"
}

watch_and_kill() {
  sleep 5s
  killall -9 quasselcore

  sleep 2s
}

create_certificate() {

  # generate key
  if [ ! -f "${QUASSELCORE_CONFIG_DIR}/quasselCert.pem" ]
  then
    log_info "create certificate"

  #  openssl req \
  #    -x509 \
  #    -nodes \
  #    -days 365 \
  #    -newkey rsa:4096 \
  #    -keyout ${QUASSELCORE_CONFIG_DIR}/quasselCert.pem \
  #    -out ${QUASSELCORE_CONFIG_DIR}/quasselCert.pem \
  #    -subj "/CN=Quassel-core"

    openssl req \
      -x509 \
      -nodes \
      -days 365 \
      -newkey rsa:4096 \
      -keyout "${QUASSELCORE_CONFIG_DIR}/quasselCert.key" \
      -out "${QUASSELCORE_CONFIG_DIR}/quasselCert.crt" \
      -subj "/CN=Quassel-core" && \
    cat \
      "${QUASSELCORE_CONFIG_DIR}/quasselCert.key" \
      "${QUASSELCORE_CONFIG_DIR}/quasselCert.crt" \
      > "${QUASSELCORE_CONFIG_DIR}/quasselCert.pem"
  fi

  if ( [ -f "${QUASSELCORE_CONFIG_DIR}/quasselCert.pem" ] && [ ! -f "${QUASSELCORE_INSTALL_DIR}/.config/quassel-irc.org/quasselCert.pem" ] )
  then
    cp -v "${QUASSELCORE_CONFIG_DIR}/quasselCert.pem" "${QUASSELCORE_INSTALL_DIR}/.config/quassel-irc.org/quasselCert.pem"
  fi
}

create_database() {

  if [ ! -f "${QUASSELCORE_CONFIG_DIR}/quassel-storage.sqlite" ]
  then
    log_info "create backend database"

    watch_and_kill &

    quasselcore \
      --configdir="${QUASSELCORE_CONFIG_DIR}" \
      --loglevel=Debug \
      --select-backend=SQLite > /dev/null
  fi
}

config_ldap() {

  config --file data/quasselcore.conf

  config --file data/quasselcore.conf --dump
}

start_quasselcore() {

  # permissions
  chown -R quassel:quassel \
    "${QUASSELCORE_CONFIG_DIR}"

  command_args="
    --configdir=${QUASSELCORE_CONFIG_DIR}
    --require-ssl
    --listen=${QUASSELCORE_LISTEN}
    --loglevel=${QUASSELCORE_LOGLEVEL}
    --port=${QUASSELCORE_PORT}"

  if [ "$(stdbool "${DEV_QUASSEL_DEBUG}")" = "y" ]
  then
    command_args="${command_args} --debug"
  fi

  log_info "start quasselcore"

  quasselcore \
    "${command_args}"
}

add_quasselcore_user() {

  if [ "$(usermanager --file "${QUASSELCORE_CONFIG_DIR}/quassel-storage.sqlite" --list | grep -c "${QUASSELCORE_USER}")" -eq 0 ]
  then
    log_info "add core user ${QUASSELCORE_USER}"

    usermanager \
      --file "${QUASSELCORE_CONFIG_DIR}/quassel-storage.sqlite" \
      --add \
      --user "${QUASSELCORE_USER}" \
      --password "${QUASSELCORE_PASSWORD}" > /dev/null
  fi

  usermanager \
    --file "${QUASSELCORE_CONFIG_DIR}/quassel-storage.sqlite" \
    --list
}


run() {

  check_data_directory

  create_certificate

  create_database

  config_ldap

  add_quasselcore_user

  start_quasselcore
}

run
