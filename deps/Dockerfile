FROM debian:trixie-slim

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/London"
ENV PKG="sudo net-tools curl git git-lfs bzip2 gnupg2 iproute2 iptables openresolv kmod"
ENV SAGER_NET="https://sing-box.app/gpg.key"

RUN apt-get -qq update \
    && apt-get -qq dist-upgrade -y \
    && apt-get -qq install $PKG \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN curl -fsSL "$SAGER_NET" | gpg --dearmor -o /etc/apt/trusted.gpg.d/sagernet.gpg \
    && echo "deb https://deb.sagernet.org * *" | tee /etc/apt/sources.list.d/sagernet.list \
    && apt-get -qq update \
    && apt-get -qq install sing-box \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /etc/apt/sources.list.d/sagernet.list \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*


