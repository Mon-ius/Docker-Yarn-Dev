#!/bin/sh

set -e

sleep 3

_D_SERVER=127.0.0.1
_D_PORT=62222
_D_USER=dev
_D_PUB_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQHW0nbmyka727Eg/mJgNzOO0DMKbXOsfS3X6P3Trnw'

D_SERVER="${D_SERVER:-$_D_SERVER}"
D_PORT="${D_PORT:-$_D_PORT}"
D_USER="${D_USER:-$_D_USER}"
D_PUB_KEY="${D_PUB_KEY:-$_D_PUB_KEY}"

if [ ! -e "/usr/bin/dev-cli" ]; then
    echo "$D_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/$D_USER"
    sudo adduser --disabled-password --gecos "" "$D_USER" && echo "$D_USER:$D_PUB_KEY" | sudo chpasswd
    sudo su "$D_USER" -c "
        mkdir -p ~/.ssh &&
        touch ~/.ssh/authorized_keys &&
        echo $D_PUB_KEY >> ~/.ssh/authorized_keys &&
        git clone --depth=1 https://github.com/AUTOM77/dotfile ~/.dotfile &&
        mv ~/.dotfile/.zsh/.*  /home/$D_USER
        rm -rf ~/.dotfile
    "
    sudo chsh -s "$(which zsh)" "${D_USER}"

    echo "ssh -NCf -o GatewayPorts=true -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -R $D_PORT:127.0.0.1:22 tun@$D_SERVER" > /usr/bin/dev-cli && echo "/usr/sbin/sshd -D" >> /usr/bin/dev-cli && chmod +x /usr/bin/dev-cli
fi

exec "$@"