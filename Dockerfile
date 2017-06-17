FROM debian:stretch-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.5.1.1
ARG EXECLINE_VER=2.3.0.1
ARG S6_VER=2.6.0.0
ARG RSPAMD_VER=1.6.1

ARG SKALIBS_SHA256_HASH="aa387f11a01751b37fd32603fdf9328a979f74f97f0172def1b0ad73b7e8d51d"
ARG EXECLINE_SHA256_HASH="2bf65aaaf808718952e05c2221b4e9472271e53ebd915c8d1d49a3e992583bf4"
ARG S6_SHA256_HASH="146dd54086063c6ffb6f554c3e92b8b12a24165fdfab24839de811f79dcf9a40"
ARG RSPAMD_SHA256_HASH="c992f1063bc59c9cbe36db4d6a74fb382049528b7310ae30e79da75d460e761e"

LABEL description="s6 + rspamd image based on Debian" \
      maintainer="Hardware <contact@meshup.net>" \
      rspamd_version="Rspamd v$RSPAMD_VER built from source" \
      s6_version="s6 v$S6_VER built from source"

ENV LC_ALL=C
ENV RSPAMD_PASSWORD=mailserver

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
    && BUILD_DEPS=" \
    cmake \
    ragel \
    pkg-config \
    liblua5.1-0-dev \
    libglib2.0-dev \
    libevent-dev \
    libsqlite3-dev \
    libicu-dev \
    libssl-dev \
    libmagic-dev \
    libfann-dev" \
 && apt-get update && apt-get install -y -q \
    ${BUILD_DEPS} \
    libevent-2.0-5 \
    libglib2.0-0 \
    libssl1.1 \
    libmagic1 \
    liblua5.1-0 \
    libfann2 \
    libsqlite3-0 \
    wget \
    openssl \
    ca-certificates \
    gnupg \
 # ### SKALIBS ###
 && cd /tmp \
 && SKALIBS_TARBALL="skalibs-${SKALIBS_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/skalibs/${SKALIBS_TARBALL} \
 && CHECKSUM=$(sha256sum ${SKALIBS_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SKALIBS_SHA256_HASH}" ]; then echo "${SKALIBS_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${SKALIBS_TARBALL} && cd skalibs-${SKALIBS_VER} \
 && ./configure --prefix=/usr --datadir=/etc \
 && make && make install \
 # ### EXECLINE ###
 && cd /tmp \
 && EXECLINE_TARBALL="execline-${EXECLINE_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/execline/${EXECLINE_TARBALL} \
 && CHECKSUM=$(sha256sum ${EXECLINE_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${EXECLINE_SHA256_HASH}" ]; then echo "${EXECLINE_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${EXECLINE_TARBALL} && cd execline-${EXECLINE_VER} \
 && ./configure --prefix=/usr \
 && make && make install \
 # ### S6 ###
 && cd /tmp \
 && S6_TARBALL="s6-${S6_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/s6/${S6_TARBALL} \
 && CHECKSUM=$(sha256sum ${S6_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${S6_SHA256_HASH}" ]; then echo "${S6_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${S6_TARBALL} && cd s6-${S6_VER} \
 && ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
 && make && make install \
 # ### RSPAMD ###
 && cd /tmp \
 && RSPAMD_TARBALL="${RSPAMD_VER}.tar.gz" \
 && wget -q https://github.com/vstakhov/rspamd/archive/${RSPAMD_TARBALL} \
 && CHECKSUM=$(sha256sum ${RSPAMD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${RSPAMD_SHA256_HASH}" ]; then echo "${RSPAMD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${RSPAMD_TARBALL} && cd rspamd-${RSPAMD_VER} \
 && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCONFDIR=/etc/rspamd \
    -DRUNDIR=/run/rspamd \
    -DDBDIR=/var/lib/rspamd \
    -DLOGDIR=/var/log/rspamd \
    -DPLUGINSDIR=/usr/share/rspamd \
    -DLIBDIR=/usr/lib/rspamd \
    -DNO_SHARED=ON \
    -DWANT_SYSTEMD_UNITS=OFF \
    . \
 && make -j${NB_CORES} \
 && make install \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
