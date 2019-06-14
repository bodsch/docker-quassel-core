# quassel-core

Dockerfile for [quassel-core](https://github.com/quassel/quassel).

This Container isr based on [Alpine]().

All dependencies (like Qt5, Ldpa, QCA) will created inline for an smaller container and dependencies.


https://github.com/Lazza/quassel-manage-users

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-quassel-core.svg)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-quassel-core.svg)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-quassel-core.svg)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-quassel-core/
[microbadger]: https://microbadger.com/images/bodsch/docker-quassel-core
[travis]: https://travis-ci.org/bodsch/docker-quassel-core


# Build
Your can use the included Makefile.

- to build the Container: `make`
- to remove the builded Docker Image: `make clean`
- starts the Container with a simple set of environment vars: `make start`
- starts the Container with Login Shell: `make shell`
- entering the Container: `make exec`
- stop (but **not kill**): `make stop`


# Contribution

Please read [Contribution](CONTRIBUTIONG.md)

# Docker Hub


# supported Environment Vars

- `QUASSELCORE_LISTEN`
- `QUASSELCORE_LOGLEVEL`
- `QUASSELCORE_PORT`
- `QUASSELCORE_USER` quasselcore
- `QUASSELCORE_PASSWORD` quasselcore

## LDAP support

- `LDAP_HOSTNAME` URI of the LDAP server - e.g. `ldap://localhost` or `ldaps://localhost`
- `LDAP_PORT` Port of the LDAP server.
- `LDAP_BIND_DN` Bind DN of the LDAP server.
- `LDAP_BIND_PASSWORD` Bind password for the bind DN of the LDAP server.
- `LDAP_BASE_DN` Search base DN of the LDAP server.
- `LDAP_FILTER` Search filter for user accounts on the LDAP server e.g. `(objectClass=posixAccount)`
- `LDAP_UID_ATTR` UID attribute to use for finding user accounts. e.g. `uid`


# Ports

 - `4646`: quasselcore
