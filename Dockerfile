
FROM alpine:3.8 as stage1

ENV \
  QUASSELCORE_INSTALL_DIR=/quasselcore

RUN \
  apk update  --quiet && \
  apk upgrade --quiet

WORKDIR /tmp

RUN \
  apk add     --quiet \
    build-base \
    openssl-dev \
    sqlite-dev \
    git \
    cmake

RUN \
  git clone git://code.qt.io/qt/qt5.git

WORKDIR /tmp/qt5

RUN \
  git checkout 5.11

RUN \
  apk add perl linux-headers

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
    -no-xkbcommon-evdev \
    -nomake examples \
    -nomake tests \
    -prefix /usr/local

RUN \
  make -j4 && \
  make install

# ---------------------------------------------------------------------------------------

WORKDIR /tmp

RUN \
  apk add curl xz

RUN \
  curl \
    --silent \
    --location \
    --retry 3 \
    http://download.kde.org/stable/qca/2.1.3/src/qca-2.1.3.tar.xz  \
  | unxz \
  | tar x -C /tmp/

WORKDIR /tmp/qca-2.1.3

RUN \
  cmake \
    -DCMAKE_PREFIX_PATH=/usr/local/ \
    -DQT_BINARY_DIR=/usr/local/bin \
    -DQT_LIBRARY_DIR=/usr/local/lib .

RUN \
  make -j4 && \
  make install

# ---------------------------------------------------------------------------------------

RUN \
  curl \
    --silent \
    --location \
    --retry 3 \
    http://mirror.eu.oneandone.net/software/openldap/openldap-release/openldap-2.4.47.tgz \
  | gunzip \
  | tar x -C /tmp/

RUN \
  apk add db-dev groff

WORKDIR /tmp/openldap-2.4.47

RUN \
  ./configure \
    --prefix=/usr/local/

RUN \
  make depend && \
  make -j4 && \
  make install

# ---------------------------------------------------------------------------------------

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
  if [[ "${BUILD_TYPE}" = "stable" ]] ; then \
    echo "switch to stable Tag ${QUASSELCORE_VERSION}" && \
    git checkout tags/${QUASSELCORE_VERSION} ; \
  fi

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
  make -j4 && \
  make install

# ---------------------------------------------------------------------------------------

RUN \
  ${QUASSELCORE_INSTALL_DIR}/bin/quasselcore --version

WORKDIR /tmp

RUN \
  git clone https://github.com/eugeii/quassel-manage-users.git manage-users && \
  chmod +x manage-users/manageusers.py

RUN \
  rm -rf \
    /usr/local/lib/libQt5Concurrent.* \
    /usr/local/lib/libQt5Test.* \
    /usr/local/lib/libQt5Xml.*

# ---------------------------------------------------------------------------------------

FROM alpine:3.8

ENV \
  TZ='Europe/Berlin' \
  QUASSELCORE_INSTALL_DIR=/quasselcore \
  HOME=${QUASSELCORE_INSTALL_DIR}

COPY --from=stage1  /tmp/manage-users/manageusers.py   /usr/bin/
COPY --from=stage1  ${QUASSELCORE_INSTALL_DIR}      ${QUASSELCORE_INSTALL_DIR}
COPY --from=stage1  /usr/local/lib/libQt5*.so.5     /usr/local/lib/
COPY --from=stage1  /usr/local/lib/libqca-qt5.so.2  /usr/local/lib/
COPY --from=stage1  /usr/local/lib/libldap-2.4.so.2 /usr/local/lib/
COPY --from=stage1  /usr/local/lib/liblber-2.4.so.2 /usr/local/lib/
COPY --from=stage1  /usr/local/plugins/sqldrivers   /usr/local/plugins/sqldrivers/

RUN \
  apk update  --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add     --quiet --no-cache --virtual .build-deps \
    shadow \
    tzdata && \
  apk add \
    openssl \
    sqlite \
    libstdc++ \
    python2 && \
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
  chown -R quassel:quassel ${QUASSELCORE_INSTALL_DIR} && \
  apk del --quiet --purge .build-deps && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/

COPY rootfs/ /

USER quassel
WORKDIR ${QUASSELCORE_INSTALL_DIR}

VOLUME ["${QUASSELCORE_INSTALL_DIR}/data"]
CMD [ "/bin/sh" ]

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
