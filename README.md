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
docker run --restart=always -itd \
    --name yarn_dev \
    -e DEV_SERVER=$DEV_SERVER -e DEV_AUTH=$DEV_AUTH \
    -e DEV_PORT=443 \
    --cap-add NET_ADMIN \
    monius/docker-yarn-dev

docker exec -it yarn_dev /bin/bash
```

> [!NOTE]
> - To stop the environment, use `docker stop yarn_dev`
> - To force remove it, use `docker rm -f yarn_dev`
> - To delete the image, use `docker rmi -f monius/docker-yarn-dev`

```sh
docker rm -f yarn_dev && docker rmi -f monius/docker-yarn-dev
```

> [!WARNING]  
> - To proxy all packages from both LAN net and container itself.

```sh
ip rule add fwmark 0x1 lookup 100
ip route add local default dev lo table 100

iptables -t mangle -N DEV
iptables -t mangle -A DEV -m mark --mark 0xff -j RETURN
iptables -t mangle -A DEV -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A DEV -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A DEV -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A DEV -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A DEV -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A DEV -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A DEV -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A DEV -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A DEV -p tcp -j TPROXY --on-port 60091 --on-ip 127.0.0.1 --tproxy-mark 0x1
iptables -t mangle -A DEV -p udp -j TPROXY --on-port 60091 --on-ip 127.0.0.1 --tproxy-mark 0x1 
iptables -t mangle -A PREROUTING -j DEV

iptables -t mangle -N DEV_MASK
iptables -t mangle -A DEV_MASK -m mark --mark 0xff -j RETURN
iptables -t mangle -A DEV_MASK -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A DEV_MASK -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A DEV_MASK -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A DEV_MASK -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A DEV_MASK -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A DEV_MASK -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A DEV_MASK -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A DEV_MASK -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A DEV_MASK -p tcp -j MARK --set-mark 0x1
iptables -t mangle -A DEV_MASK -p udp -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT -j DEV_MASK
```

> [!CAUTION]
> - To prune all docker containers and images

```sh
docker rm -f $(docker ps -a -q) && docker rmi -f $(docker images -a -q)
```