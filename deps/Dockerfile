FROM debian:trixie-slim

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/London"
ENV PKG="sudo net-tools curl git git-lfs bzip2 gnupg2 dnsutils"
ENV B1="deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware"
ENV B2="deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm-updates main contrib non-free non-free-firmware"

RUN echo $B1 | tee /etc/apt/sources.list
RUN echo $B2 | tee -a /etc/apt/sources.list

RUN apt-get -qq update \
    && apt-get -qq dist-upgrade -y \
    && apt-get -qq install $PKG \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

