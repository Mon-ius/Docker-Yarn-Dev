# Docker-Yarn-Dev

[![CI Status](https://github.com/Mon-ius/Docker-Yarn-Dev/workflows/build/badge.svg)](https://github.com/Mon-ius/Docker-Yarn-Dev/actions?query=workflow:build)
[![Docker Pulls](https://flat.badgen.net/docker/pulls/monius/docker-yarn-dev?icon=docker)](https://hub.docker.com/r/monius/docker-yarn-dev)
[![Code Size](https://img.shields.io/github/languages/code-size/Mon-ius/Docker-Yarn-Dev)](https://github.com/Mon-ius/Docker-Yarn-Dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> Modern develop environment, with Yarn.

Multi-platform: `linux/amd64`, `linux/arm64`, `linux/arm`, `linux/s390x` and `linux/riscv64`;

> [!IMPORTANT]  
> For permission related issue to use `docker` instead of `sudo docker`

```sh
sudo chmod 666 /var/run/docker.sock
sudo groupadd docker
sudo usermod -aG docker $USER
```

> [!TIP]
> - To use customized `port`, set `-e DEV_PORT=$DEV_PORT`
> - To use Encryption with `user` and `passwd`, set `DEV_SERVER=$DEV_SERVER` and `-e DEV_AUTH=$DEV_AUTH`

```sh
docker run --privileged --restart=always -itd \
    --name yarn_dev \
    -e DEV_SERVER=$DEV_SERVER -e DEV_AUTH=$DEV_AUTH \
    -e DEV_PORT=443 \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --cap-add NET_ADMIN \
    --cap-add NET_RAW \
    --cap-add SYS_MODULE \
    --device=/dev/net/tun \
    monius/docker-yarn-dev:deps

docker logs yarn_dev
docker exec -it yarn_dev /bin/bash
```

> [!NOTE]
> - To stop the environment, use `docker stop yarn_dev`
> - To force remove it, use `docker rm -f yarn_dev`
> - To delete the image, use `docker rmi -f monius/docker-yarn-dev`

```sh
docker rm -f yarn_dev && docker rmi -f monius/docker-yarn-dev
```

> [!CAUTION]
> - To prune all docker containers and images

```sh
docker rm -f $(docker ps -a -q) && docker rmi -f $(docker images -a -q)
```