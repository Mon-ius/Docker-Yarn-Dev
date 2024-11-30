FROM debian:trixie-slim

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/London"
ENV PKG="sudo net-tools curl git git-lfs bzip2 gnupg2 dnsutils"
ENV SAGER_NET="https://sing-box.app/gpg.key"
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

RUN curl -fsSL "$SAGER_NET" | gpg --dearmor -o /etc/apt/trusted.gpg.d/sagernet.gpg \
    && echo "deb https://deb.sagernet.org * *" | tee /etc/apt/sources.list.d/sagernet.list
    && apt-get -qq update \
    && apt-get -qq install sing-box \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /etc/apt/sources.list.d/sagernet.list \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*


