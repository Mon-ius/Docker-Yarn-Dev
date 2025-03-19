FROM monius/docker-yarn-dev:deps

LABEL maintainer="M0nius <m0niusplus@gmail.com>" \
    debian-version="12.10" \
    org.opencontainers.image.title="Docker-Yarn-Dev" \
    org.opencontainers.image.description="Modern develop environment, just in box!" \
    org.opencontainers.image.authors="M0nius <m0niusplus@gmail.com>" \
    org.opencontainers.image.vendor="M0nius Tech" \
    org.opencontainers.image.version="2.2.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/monius/docker-yarn-dev" \
    org.opencontainers.image.source="https://github.com/Mon-ius/Docker-Yarn-Dev" \
    org.opencontainers.image.base.name="docker.io/monius/docker-yarn-dev"

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["dev-cli"]