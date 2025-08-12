FROM monius/docker-yarn-dev:base

LABEL maintainer="M0nius <m0niusplus@gmail.com>" \
    debian-version="12.11" \
    org.opencontainers.image.title="Docker-Yarn-Dev" \
    org.opencontainers.image.description="Modern develop environment, just in box!" \
    org.opencontainers.image.authors="M0nius <m0niusplus@gmail.com>" \
    org.opencontainers.image.vendor="M0nius Tech" \
    org.opencontainers.image.version="3.0.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/monius/docker-yarn-dev" \
    org.opencontainers.image.source="https://github.com/Mon-ius/Docker-Yarn-Dev" \
    org.opencontainers.image.base.name="docker.io/monius/docker-yarn-dev:cpu"

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/London"
ENV PKG="openssh-server tmux vim zsh"

RUN apt-get -qq update \
    && apt-get -qq dist-upgrade -y \
    && apt-get -qq install "$PKG" \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["dev-cli"]