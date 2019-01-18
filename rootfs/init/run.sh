#!/bin/sh

LISTEN=${LISTEN:-"0.0.0.0"}
LOGLEVEL=${LOGLEVEL:-"Info"}
PORT=${PORT:="4242"}
CONFIG_DIR=${QUASSELCORE_INSTALL_DIR}/data

QUASSELCORE_USER=${QUASSELCORE_USER:-quasselcore}
QUASSELCORE_PASSWORD=${QUASSELCORE_PASSWORD:-quasselcore}

export PATH=$PATH:${QUASSELCORE_INSTALL_DIR}/bin

. /init/output.sh

# -------------------------------------------------------------------------------------------------

finish() {
  rv=$?
  [ ${rv} -gt 0 ] && echo -e "\033[38;5;202m\033[1mexit with signal '${rv}'\033[0m"
  exit $rv
}

trap finish SIGINT SIGTERM INT TERM EXIT

# -------------------------------------------------------------------------------------------------

watch_and_kill() {
  sleep 5s
  killall -9 quasselcore
}

create_vertificate() {

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

  log_info "start quasselcore"

  quasselcore \
    ${command_args}
}

add_quasselcore_user() {

  if [ $(python2 /usr/bin/manageusers.py list | wc -l) -eq 1 ]
  then
    log_info "add core user ${QUASSELCORE_USER}"

    python2 \
      /usr/bin/manageusers.py add \
      ${QUASSELCORE_USER} \
      ${QUASSELCORE_PASSWORD} > /dev/null
  fi
}


run() {

  create_vertificate

  create_database

  add_quasselcore_user

  start_quasselcore

  #python2 /usr/bin/manageusers.py list
}




#    if settings.value("Config/Version") is None:
#        settings.setValue("Config/Version", 1)
#
#    # Set Auth Settings
#    authSettings = {
#        "Authenticator" : "LDAP",
#        "AuthProperties" : {
#            "BaseDN": os.environ["LDAP_BASE_DN"],
#            "BindDN": os.environ["LDAP_BIND_DN"],
#            "BindPassword": os.environ["LDAP_BIND_PASSWORD"],
#            "Filter": os.environ["LDAP_FILTER"],
#            "Hostname": os.environ["LDAP_HOSTNAME"],
#            "Port": os.environ["LDAP_PORT"],
#            "UidAttribute": os.environ["LDAP_UID_ATTR"]
#        }




run
