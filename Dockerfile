FROM monius/docker-yarn-dev:deps

LABEL maintainer="M0nius <m0niusplus@gmail.com>" \
    debian-version="12.8" \
    org.opencontainers.image.title="Docker-Yarn-Dev" \
    org.opencontainers.image.description="Modern develop environment, just in box!" \
    org.opencontainers.image.authors="M0nius <m0niusplus@gmail.com>" \
    org.opencontainers.image.vendor="M0nius Tech" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/monius/docker-yarn-dev" \
    org.opencontainers.image.source="https://github.com/Mon-ius/Docker-Yarn-Dev" \
    org.opencontainers.image.base.name="docker.io/monius/docker-yarn-dev"

ENV SAGER_NET="https://sing-box.app/gpg.key"
ENV NODE_23="https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key"

RUN curl -fsSL "$SAGER_NET" | gpg --dearmor -o /etc/apt/trusted.gpg.d/sagernet.gpg \
    && echo "deb https://deb.sagernet.org * *" | tee /etc/apt/sources.list.d/sagernet.list

RUN cat /etc/apt/sources.list.d/sagernet.list \
    && apt-get -qq update \
    && apt-get -qq install sing-box \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /etc/apt/sources.list.d/sagernet.list \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN curl -fsSL "$NODE_23" | gpg --dearmor -o /etc/apt/trusted.gpg.d/node_23.gpg \
    && export ARCH=$(dpkg --print-architecture) \
    && echo "deb [arch=$ARCH] https://deb.nodesource.com/node_23.x nodistro main" | tee /etc/apt/sources.list.d/node.list \
    && apt-get -qq update \
    && apt-get -qq install nodejs \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /etc/apt/sources.list.d/node.list \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]