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
    org.opencontainers.image.base.name="docker.io/monius/docker-yarn-dev:gpu"

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/London"
ENV PKG="openssh-server tmux vim zsh unzip g++ cmake"
ENV LibTorch="https://download.pytorch.org/libtorch/nightly/cu129/libtorch-shared-with-deps-latest.zip"
ENV NVIDIA="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-archive-keyring.gpg"

RUN apt-get -qq update \
    && apt-get -qq dist-upgrade -y \
    && apt-get -qq install $PKG \
    && apt-get -qq autoremove --purge \
    && apt-get -qq autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN Torch=/opt/torch && \ 
    curl -fsSL -C - $LibTorch -o libtorch.zip && \
    unzip libtorch.zip -d $Torch && \
    rm libtorch.zip

RUN curl -fsSL "$NVIDIA" | tee /etc/apt/trusted.gpg.d/cuda-archive-keyring.gpg && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" | tee /etc/apt/sources.list.d/cuda.list && \
    apt-get update && apt-get install -y cuda-toolkit-13-0

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["dev-cli"]