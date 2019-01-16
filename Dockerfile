
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
  git clone https://github.com/eugeii/quassel-manage-users.git && \
  chmod +x quassel-manage-users/manageusers.py

WORKDIR /tmp/quassel

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

# ---------------------------------------------------------------------------------------

FROM alpine:edge

ENV \
  HOME /var/lib/quassel

RUN \
  apk update  --quiet --no-cache && \
  apk upgrade --quiet --no-cache

RUN \
  apk add \
    qt5-qtbase-sqlite \
    qca \
    openssl \
    icu \
    libstdc++ \
    python3

COPY --from=stage1  /usr/lib/libQt5Script*       /usr/lib/
COPY --from=stage1  /usr/lib/libquassel*  /usr/lib/
COPY --from=stage1  /tmp/quassel-manage-users/manageusers.py   /usr/bin/
#COPY --from=stage1  /usr/lib/libqca*      /usr/lib/
#COPY --from=stage1  /usr/lib/libicui18n*  /usr/lib/
#COPY --from=stage1  /usr/lib/libicuuc*    /usr/lib/
#COPY --from=stage1  /usr/lib/libicudata*  /usr/lib/
#COPY --from=stage1  /usr/lib/libpcre*     /usr/lib/
#COPY --from=stage1  /usr/lib/libglib*     /usr/lib/
#COPY --from=stage1  /usr/lib/libintl*     /usr/lib/
#COPY --from=stage1  /lib/libcrypto*       /lib/
#COPY --from=stage1  /lib/libssl*          /lib/
COPY --from=stage1  /usr/bin/quasselcore  /usr/bin/

RUN \
  ldd /usr/bin/quasselcore

COPY rootfs/ /

CMD [ "/bin/sh" ]

# https://quassel-irc.org/pub/quassel-0.13.0.tar.bz2
EXPOSE 4242
VOLUME /var/lib/quassel

# ---------------------------------------------------------------------------------------

#LABEL \
#  version="1709" \
#  org.label-schema.build-date=${BUILD_DATE} \
#  org.label-schema.name="boilerplate Docker Image" \
#  org.label-schema.description="Inofficial boilerplate Docker Image" \
#  org.label-schema.url="https://boilerplate.io/" \
#  org.label-schema.vcs-url="https://github.com/bodsch/boilerplate" \
#  org.label-schema.vendor="Bodo Schulz" \
#  org.label-schema.version=${VERSION} \
#  org.label-schema.schema-version="1.0" \
#  com.microscaling.docker.dockerfile="/Dockerfile" \
#  com.microscaling.license="GNU General Public License v3.0"

# ---------------------------------------------------------------------------------------

#/tmp/quassel/build # ldd /usr/bin/quasselcore
#        /lib/ld-musl-x86_64.so.1 (0x7f500703a000)
#        libquassel-core.so.0.13.50 => /usr/lib/libquassel-core.so.0.13.50 (0x7f5006e13000)
#        libquassel-common.so.0.13.50 => /usr/lib/libquassel-common.so.0.13.50 (0x7f5006ca3000)
#        libQt5Core.so.5 => /usr/lib/libQt5Core.so.5 (0x7f5006746000)
#        libstdc++.so.6 => /usr/lib/libstdc++.so.6 (0x7f50065f1000)
#        libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7f50065dd000)
#        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f500703a000)
#        libQt5Script.so.5 => /usr/lib/libQt5Script.so.5 (0x7f5006443000)
#        libQt5Sql.so.5 => /usr/lib/libQt5Sql.so.5 (0x7f500640c000)
#        libqca-qt5.so.2 => /usr/lib/libqca-qt5.so.2 (0x7f500631a000)
#        libQt5Network.so.5 => /usr/lib/libQt5Network.so.5 (0x7f50061dc000)
#        libz.so.1 => /lib/libz.so.1 (0x7f5005fc5000)
#        libicui18n.so.62 => /usr/lib/libicui18n.so.62 (0x7f5005d65000)
#        libicuuc.so.62 => /usr/lib/libicuuc.so.62 (0x7f5005bd8000)
#        libpcre2-16.so.0 => /usr/lib/libpcre2-16.so.0 (0x7f5005b54000)
#        libglib-2.0.so.0 => /usr/lib/libglib-2.0.so.0 (0x7f5005a5c000)
#        libssl.so.1.1 => /lib/libssl.so.1.1 (0x7f50059dc000)
#        libcrypto.so.1.1 => /lib/libcrypto.so.1.1 (0x7f500575f000)
#        libicudata.so.62 => /usr/lib/libicudata.so.62 (0x7f5003dc4000)
#        libpcre.so.1 => /usr/lib/libpcre.so.1 (0x7f5003d67000)
#        libintl.so.8 => /usr/lib/libintl.so.8 (0x7f5003b59000)

