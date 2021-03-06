# ---------------------------------------------------------------------------------------
#
# get and build Qt 5.12

FROM alpine:3.11 as stage1

ARG BUILD_TYPE=stable

ENV \
  QT_VERSION=5.12.8 \
  QUASSELCORE_INSTALL_DIR=/quasselcore

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet

# hadolint ignore=DL3018,DL3019
RUN \
  apk add --quiet   \
    build-base \
    openssl-dev \
    sqlite-dev \
    python3-dev \
    curl \
    perl \
    linux-headers \
    p7zip \
    git \
    cmake

WORKDIR /tmp

RUN \
  git clone https://code.qt.io/qt/qt5.git

WORKDIR /tmp/qt5

# hadolint ignore=DL4006
RUN \
  if [ "${BUILD_TYPE}" = "stable" ] ; then \
    echo "switch to stable Tag ${QT_VERSION}" && \
    git checkout "tags/v${QT_VERSION}" 2> /dev/null ; \
  fi && \
  set -o pipefail && git describe --tags --always | sed 's/^v//'

RUN \
  ./init-repository --module-subset=qtbase,qtscript

RUN \
  ./configure \
    -confirm-license \
    -opensource \
    -release \
    -strip \
    -silent \
    -ssl \
    -sqlite \
    -no-gif \
    -no-ico \
    -no-libpng \
    -no-libjpeg \
    -no-harfbuzz \
    -no-freetype \
    -no-opengl \
    -no-accessibility \
    -no-gui \
    -no-widgets \
    -no-dbus \
    -no-linuxfb \
    -no-libudev \
    -no-sm \
    -no-evdev \
    -no-xcb \
    -no-xkb \
    -nomake examples \
    -nomake tests \
    -prefix /usr/local

RUN \
  make -j "$(nproc)" && \
  make install

# ---------------------------------------------------------------------------------------
#
# get and build QCA 2.1.3

FROM alpine:3.11 as stage2

ENV \
  QUASSELCORE_INSTALL_DIR=/quasselcore \
  QCA_VERSION=2.3.0

COPY --from=stage1  /usr/local                           /usr/local

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet

# hadolint ignore=DL3018,DL3019
RUN \
  apk add --quiet \
    build-base \
    openssl-dev \
    sqlite-dev \
    python3-dev \
    curl \
    perl \
    linux-headers \
    p7zip \
    git \
    cmake

WORKDIR /tmp

RUN \
  git clone https://github.com/KDE/qca.git

WORKDIR /tmp/qca

# hadolint ignore=DL4006
RUN \
  if [ "${BUILD_TYPE}" = "stable" ] ; then \
    echo "switch to stable Tag ${QCA_VERSION}" && \
    git checkout "tags/v${QCA_VERSION}" 2> /dev/null ; \
  fi && \
  set -o pipefail && git describe --tags --always | sed 's/^v//'

RUN \
  cmake \
    -DCMAKE_INSTALL_PREFIX=/usr/local/ \
    -DCMAKE_PREFIX_PATH=/usr/local/ \
    -DQT_BINARY_DIR=/usr/local/bin \
    -DQT_LIBRARY_DIR=/usr/local/lib .

RUN \
  make -j "$(nproc)" && \
  make install

# ---------------------------------------------------------------------------------------
#
# get and build quassel-core tools

FROM alpine:3.11 as stage3

ENV \
  QUASSELCORE_INSTALL_DIR=/quasselcore

COPY --from=stage2  /usr/local                           /usr/local

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet

# hadolint ignore=DL3018,DL3019
RUN \
  apk add --quiet \
    build-base \
    openssl-dev \
    sqlite-dev \
    linux-headers \
    git

WORKDIR /tmp

RUN \
  git clone https://github.com/bodsch/quassel-core-tools.git

WORKDIR /tmp/quassel-core-tools/config

RUN \
  qmake && \
  make

WORKDIR /tmp/quassel-core-tools/usermanager

RUN \
  qmake && \
  make

# ---------------------------------------------------------------------------------------
#
# get and build openldap

FROM alpine:3.11 as stage4

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet

# hadolint ignore=DL3018,DL3019
RUN \
  apk add --quiet \
    build-base \
    curl \
    openssl-dev \
    sqlite-dev \
    linux-headers \
    git \
    db-dev \
    groff

WORKDIR /tmp

# hadolint ignore=DL4006
RUN \
  curl \
    --silent \
    --location \
    --retry 3 \
    http://mirror.eu.oneandone.net/software/openldap/openldap-release/openldap-2.4.47.tgz \
  | gunzip \
  | tar x -C /tmp/

WORKDIR /tmp/openldap-2.4.47

RUN \
  ./configure \
    --prefix=/usr/local/

RUN \
  make depend && \
  make -j "$(nproc)" && \
  make install

# ---------------------------------------------------------------------------------------
#
# get and build quassel

FROM alpine:3.11 as stage5

ENV \
  QUASSELCORE_INSTALL_DIR=/quasselcore

COPY --from=stage1  /usr/local                           /usr/local
COPY --from=stage2  /usr/local                           /usr/local
COPY --from=stage4  /usr/local                           /usr/local
COPY --from=stage4  /tmp/openldap-2.4.47                 /tmp/openldap-2.4.47

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet

# hadolint ignore=DL3018,DL3019
RUN \
  apk add --quiet \
    build-base \
    cmake \
    openssl-dev \
    sqlite-dev \
    linux-headers \
    git \
    db-dev \
    groff

WORKDIR /tmp

RUN \
  git clone https://github.com/quassel/quassel

WORKDIR /tmp/quassel

ARG VCS_REF
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_TYPE=stable
ARG QUASSELCORE_VERSION

RUN \
  if [ "${BUILD_TYPE}" = "stable" ] ; then \
    echo "switch to stable Tag ${QUASSELCORE_VERSION}" && \
    git checkout tags/${QUASSELCORE_VERSION} ; \
  fi

# hadolint ignore=DL4006
RUN \
  QUASSELCORE_VERSION=$(git describe --tags --always | sed 's/^v//') && \
  echo " => build version ${QUASSELCORE_VERSION}"

RUN \
  sed -i 's|CMAKE_AUTOUIC ON|CMAKE_AUTOUIC OFF|g' CMakeLists.txt

RUN \
  mkdir build

WORKDIR /tmp/quassel/build

RUN \
  cmake \
    -DCMAKE_PREFIX_PATH=/usr/local/ \
    -DUSE_QT4=OFF \
    -DUSE_QT5=ON \
    -DUSE_CCACHE=OFF \
    -DWITH_WEBKIT=OFF \
    -DWITH_KDE=OFF \
    -DWITH_LDAP=ON \
    -DWANT_MONO=OFF \
    -DWITH_OXYGEN_ICONS=OFF \
    -DWANT_CORE=ON \
    -DWANT_QTCLIENT=OFF \
    -DWITH_BUNDLED_ICONS=OFF \
    -DLDAP_INCLUDE_DIR=/tmp/openldap-2.4.47/include/ \
    -DCMAKE_INSTALL_PREFIX=${QUASSELCORE_INSTALL_DIR} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    ..

RUN \
  make -j "$(nproc)" && \
  make install

# ---------------------------------------------------------------------------------------

RUN \
  ${QUASSELCORE_INSTALL_DIR}/bin/quasselcore --version

RUN \
  rm -rf \
    /usr/local/lib/libQt5Concurrent.* \
    /usr/local/lib/libQt5Test.* \
    /usr/local/lib/libQt5Xml.*

WORKDIR /tmp

# ---------------------------------------------------------------------------------------

FROM alpine:3.11

ENV \
  TZ='Europe/Berlin' \
  QUASSELCORE_INSTALL_DIR=/quasselcore \
  HOME=${QUASSELCORE_INSTALL_DIR}

COPY --from=stage5  ${QUASSELCORE_INSTALL_DIR}                            ${QUASSELCORE_INSTALL_DIR}
COPY --from=stage3  /tmp/quassel-core-tools/config/config                 ${QUASSELCORE_INSTALL_DIR}/bin/
COPY --from=stage3  /tmp/quassel-core-tools/usermanager/usermanager       ${QUASSELCORE_INSTALL_DIR}/bin/
COPY --from=stage1  /usr/local/lib/libQt5*.so.5                           /usr/local/lib/
COPY --from=stage2  /usr/local/lib/libqca-qt5.so.2                        /usr/local/lib/
COPY --from=stage4  /usr/local/lib/libldap-2.4.so.2                       /usr/local/lib/
COPY --from=stage4  /usr/local/lib/liblber-2.4.so.2                       /usr/local/lib/
COPY --from=stage1  /usr/local/plugins/sqldrivers                         /usr/local/plugins/sqldrivers/

# hadolint ignore=DL3017,DL3018,DL3019
RUN \
  apk update  --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add     --quiet --no-cache --virtual .build-deps \
    shadow \
    tzdata && \
  apk add \
    openssl \
    sqlite-libs \
    libstdc++ && \
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  echo "${TZ}" > /etc/localtime && \
  /usr/sbin/useradd \
    --user-group \
    --shell /bin/false \
    --comment "User for quassel core" \
    --no-create-home \
    --home-dir ${QUASSELCORE_INSTALL_DIR} \
    --uid 1000 \
    quassel && \
  mkdir -v ${QUASSELCORE_INSTALL_DIR}/data && \
  chown -R quassel:quassel ${QUASSELCORE_INSTALL_DIR} && \
  apk del --quiet --purge .build-deps && \
  rm -rf \
    /tmp/* \
    /src/* \
    /var/cache/apk/

COPY rootfs/ /

USER quassel
WORKDIR ${QUASSELCORE_INSTALL_DIR}

VOLUME ["${QUASSELCORE_INSTALL_DIR}/data"]
CMD ["/init/run.sh"]

EXPOSE 4242

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  --start-period=10s \
  CMD ps ax | grep -v grep | grep -c quasselcore || exit 1

# ---------------------------------------------------------------------------------------

LABEL \
  version=${BUILD_VERSION} \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="quassel core Docker Image" \
  org.label-schema.description="Inofficial quassel core Docker Image" \
  org.label-schema.url="https://github.com/quassel/quassel" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-quassel-core" \
  org.label-schema.vcs-ref=${VCS_REF} \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${QUASSELCORE_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license=""

# ---------------------------------------------------------------------------------------
