#!/bin/sh

set -e

corepack enable && corepack prepare yarn@stable --activate

sleep 3

_X_SERVER=example.com
_X_PORT=443
_X_AUTH=passwd

_D_SERVER=127.0.0.1
_D_PORT=60996
_D_USER=dev
_D_PUB_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQHW0nbmyka727Eg/mJgNzOO0DMKbXOsfS3X6P3Trnw'

X_SERVER="${X_SERVER:-$_X_SERVER}"
X_PORT="${X_PORT:-$_X_PORT}"
X_AUTH="${X_AUTH:-$_X_AUTH}"

D_SERVER="${D_SERVER:-$_D_SERVER}"
D_PORT="${D_PORT:-$_D_PORT}"
D_USER="${D_USER:-$_D_USER}"
D_PUB_KEY="${D_PUB_KEY:-$_D_PUB_KEY}"

if [ -n "$X_SERVER" ] && [ -n "$X_PORT" ] && [ -n "$X_AUTH" ]; then
AUTH_PART=$(cat <<EOF
    {
        "tag": "Proxy",
        "type": "hysteria2",
        "server": "$X_SERVER",
        "server_port": $X_PORT,
        "up_mbps": 1000,
        "down_mbps": 1000,
        "password": "$X_AUTH",
        "connect_timeout": "5s",
        "tcp_fast_open": true,
        "tls": {
            "enabled": true,
            "server_name": "$X_SERVER",
            "alpn": [
                "h3"
            ]
        }
    }
EOF
)
else
    AUTH_PART=""
fi

MAIN_PART=$(cat <<EOF
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "cache_id": "v1",
            "store_fakeip": true
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "google",
                "address": "tls://8.8.8.8",
                "detour": "Proxy"
            },
            {
                "tag": "fallback",
                "address": "8.8.8.8",
                "address_resolver": "google",
                "detour": "Proxy"
            },
            {
                "tag": "local-dns",
                "address": "223.5.5.5",
                "detour": "direct"
            },
            {
                "tag": "block-dns",
                "address": "rcode://success"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "local-dns"
            },
            {
                "rule_set": [
                    "Youtube0"
                ],
                "server": "fallback"
            },
            {
                "rule_set": [
                    "Telegram1"
                ],
                "server": "fallback"
            },
            {
                "rule_set": [
                    "Github0"
                ],
                "server": "fallback"
            },
            {
                "rule_set": [
                    "Openai0"
                ],
                "server": "fallback"
            },
            {
                "rule_set": [
                    "Netflix0"
                ],
                "server": "fallback"
            },
            {
                "rule_set": [
                    "Google0"
                ],
                "server": "fallback"
            },
            {
                "rule_set": [
                    "Direct1"
                ],
                "server": "local-dns"
            },
            {
                "query_type": [
                    "A"
                ],
                "rewrite_ttl": 1,
                "server": "fallback"
            }
        ],
        "strategy": "ipv4_only"
    },
    "inbounds": [
        {
            "type": "tproxy",
            "listen": "::",
            "listen_port": 60091,
            "sniff": true,
            "udp_fragment": true,
            "tcp_fast_open": true,
            "tcp_multi_path": false,
            "udp_timeout": "5m",
            "sniff_override_destination": false,
            "domain_strategy": "prefer_ipv4"
        }
    ],
    "route": {
        "rule_set": [
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Youtube0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/youtube.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Telegram0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geoip/telegram.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Telegram1",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/telegram.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Github0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/github.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Openai0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/openai.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Netflix0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/netflix.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Netflix1",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo-lite/geoip/netflix.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Google0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/google.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Direct0",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geoip/cn.srs"
            },
            {
                "type": "remote",
                "format": "binary",
                "download_detour": "Proxy",
                "tag": "Direct1",
                "url": "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/cn.srs"
            }
        ],
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            },
            {
                "port": 53,
                "outbound": "dns-out"
            },
            {
                "type": "logical",
                "mode": "or",
                "rules": [
                    {
                        "port": 853
                    },
                    {
                        "network": "udp",
                        "port": 443
                    },
                    {
                        "protocol": "stun"
                    }
                ],
                "outbound": "block"
            },
            {
                "rule_set": [
                    "Youtube0"
                ],
                "outbound": "Youtube"
            },
            {
                "rule_set": [
                    "Telegram0",
                    "Telegram1"
                ],
                "outbound": "Telegram"
            },
            {
                "rule_set": [
                    "Github0"
                ],
                "outbound": "Github"
            },
            {
                "rule_set": [
                    "Openai0"
                ],
                "outbound": "Openai"
            },
            {
                "rule_set": [
                    "Netflix0",
                    "Netflix1"
                ],
                "outbound": "Netflix"
            },
            {
                "rule_set": [
                    "Google0"
                ],
                "outbound": "Google"
            },
            {
                "rule_set": [
                    "Direct0",
                    "Direct1"
                ],
                "outbound": "direct"
            },
            {
                "ip_is_private": true,
                "outbound": "direct"
            }
        ],
        "auto_detect_interface": true,
        "final": "Proxy"
    },
    "outbounds": [
        {
            "tag": "Youtube",
            "outbounds": [
                "Proxy"
            ],
            "interrupt_exist_connections": true,
            "type": "selector"
        },
        {
            "tag": "Telegram",
            "outbounds": [
                "Proxy"
            ],
            "interrupt_exist_connections": true,
            "type": "selector"
        },
        {
            "tag": "Github",
            "outbounds": [
                "Proxy"
            ],
            "interrupt_exist_connections": true,
            "type": "selector"
        },
        {
            "tag": "Openai",
            "outbounds": [
                "Proxy"
            ],
            "interrupt_exist_connections": true,
            "type": "selector"
        },
        {
            "tag": "Netflix",
            "outbounds": [
                "Proxy"
            ],
            "interrupt_exist_connections": true,
            "type": "selector"
        },
        {
            "tag": "Google",
            "outbounds": [
                "Proxy"
            ],
            "interrupt_exist_connections": true,
            "type": "selector"
        },
        {
            "type": "direct",
            "tag": "direct"
        },
        {
            "type": "dns",
            "tag": "dns-out"
        },
        {
            "type": "block",
            "tag": "block"
        },
$AUTH_PART
    ]
}
EOF
)

if [ ! -e "/etc/sing-box/x.json" ]; then
    echo "$MAIN_PART" | tee /etc/sing-box/x.json
fi

if ip rule list | grep -q "fwmark 0x1 lookup 100"; then
    echo "Rules exist..."
else
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
    iptables -t mangle -A DEV -p tcp --dport 22 -j RETURN
    iptables -t mangle -A DEV -p tcp --sport 22 -j RETURN
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
    iptables -t mangle -A DEV_MASK -p tcp --dport 22 -j RETURN
    iptables -t mangle -A DEV_MASK -p tcp --sport 22 -j RETURN
    iptables -t mangle -A DEV_MASK -p tcp -j MARK --set-mark 0x1
    iptables -t mangle -A DEV_MASK -p udp -j MARK --set-mark 0x1
    iptables -t mangle -A OUTPUT -j DEV_MASK
fi

sleep 1

if tmux has-session -t 0 2>/dev/null; then
    echo "tmux session already exists."
else
    tmux new -d -s 0 'sing-box -c /etc/sing-box/x.json run'
fi

sleep 1

if id "$D_USER" >/dev/null 2>&1; then
    echo "User '$D_USER' already exists."
else
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
fi

if [ -e "/root/.ssh/id_ed25519" ] && [ ! -e "/usr/bin/dev-cli" ]; then
    echo "ssh -NCf -o GatewayPorts=true -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -R $D_PORT:127.0.0.1:22 tun@$D_SERVER" > /usr/bin/dev-cli && echo "/usr/sbin/sshd -D" >> /usr/bin/dev-cli && chmod +x /usr/bin/dev-cli
fi

exec "$@"