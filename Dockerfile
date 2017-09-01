FROM debian:stretch-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.6.0.0
ARG EXECLINE_VER=2.3.0.2
ARG S6_VER=2.6.1.0
ARG RSPAMD_VER=1.6.3

ARG SKALIBS_SHA256_HASH="3572cb8c7d2ae9d16da5a0f3d23b48e013e0c957f1329d100f04dd5accb054c3"
ARG EXECLINE_SHA256_HASH="c11650651a7230bd5687945a7698b2da3fe13c3c0eb15e296bb91769d4775f45"
ARG S6_SHA256_HASH="f0de303791134302f2630b9fe76a936b064e1e3aa772c8ae1b891155a6ea2c79"
ARG RSPAMD_SHA256_HASH="0d89fc4966c71b209a0f566458b1651dfa11b651b5e772cbe599177270e8c13f"

LABEL description="s6 + rspamd image based on Debian" \
      maintainer="Hardware <contact@meshup.net>" \
      rspamd_version="Rspamd v$RSPAMD_VER built from source" \
      s6_version="s6 v$S6_VER built from source"

ENV LC_ALL=C

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
    && BUILD_DEPS=" \
    cmake \
    gcc \
    make \
    ragel \
    wget \
    pkg-config \
    liblua5.1-0-dev \
    libglib2.0-dev \
    libevent-dev \
    libsqlite3-dev \
    libicu-dev \
    libssl-dev \
    libmagic-dev \
    libfann-dev" \
 && apt-get update && apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    libevent-2.0-5 \
    libglib2.0-0 \
    libssl1.1 \
    libmagic1 \
    liblua5.1-0 \
    libfann2 \
    libsqlite3-0 \
    sqlite3 \
    openssl \
    ca-certificates \
    gnupg \
    dirmngr \
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
    -DDBDIR=/var/mail/rspamd \
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
