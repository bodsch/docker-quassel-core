
FROM alpine:edge as stage1

RUN \
  apk update  --quiet && \
  apk upgrade --quiet

WORKDIR /tmp

RUN \
  apk add \
    build-base \
    openssl-dev \
    boost-dev \
    git \
    cmake

RUN \
  apk add \
    qt5-qtbase-dev || true

RUN \
  apk add \
    qt5-qtscript-dev || true

RUN \
  apk add \
    qca-dev || true

RUN \
  ln -sf /usr/lib/qt5/bin/uic /usr/bin/uic

RUN \
  git clone https://github.com/quassel/quassel

RUN \
  git clone https://github.com/eugeii/quassel-manage-users.git manage-users && \
  chmod +x manage-users/manageusers.py

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
    -DUSE_QT4=OFF \
    -DUSE_QT5=ON \
    -DUSE_CCACHE=OFF \
    -DWITH_WEBKIT=OFF \
    -DWITH_KDE=OFF \
    -DWANT_MONO=OFF \
    -DWITH_OXYGEN_ICONS=OFF \
    -DWANT_CORE=ON \
    -DWANT_QTCLIENT=OFF \
    -DWITH_BUNDLED_ICONS=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=lib \
    .. && \
  make && \
  make install

WORKDIR /tmp

RUN \
  #git clone https://github.com/eugeii/quassel-manage-users.git manage-users && \
  ls -l manage-users/manageusers.py && \
  chmod +x manage-users/manageusers.py

RUN \
  ls -lth /usr/lib/*

RUN \
  ls -lth /usr/bin/*

# ---------------------------------------------------------------------------------------

FROM alpine:edge

ENV \
  HOME=/var/lib/quassel \
  TZ='Europe/Berlin'

COPY --from=stage1  /tmp/manage-users/manageusers.py   /usr/bin/
COPY --from=stage1  /usr/lib/libQt5Script*       /usr/lib/
COPY --from=stage1  /usr/bin/quasselcore         /usr/bin/
# works only with master branch
#if [[ "${BUILD_TYPE}" != "stable" ]] ; then \
#COPY --from=stage1  /usr/lib/libquassel*         /usr/lib/ ; \
#fi

RUN \
  apk update  --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add     --quiet --no-cache --virtual .build-deps \
    shadow \
    tzdata && \
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  echo "${TZ}" > /etc/localtime && \
  /usr/sbin/useradd \
    --user-group \
    --shell /bin/false \
    --comment "User for quassel core" \
    --no-create-home \
    --home-dir /var/lib/quassel \
    --uid 1000 \
    quassel && \
  apk add \
    qt5-qtbase-sqlite \
    qca \
    openssl \
    icu \
    libstdc++ \
    python2 && \
  apk del --quiet --purge .build-deps && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/

#RUN \
#  ldd /usr/bin/quasselcore

COPY rootfs/ /

USER quassel
WORKDIR /var/lib/quassel

VOLUME ["/var/lib/quassel"]
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
