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
PROXY_PART=$(cat <<EOF
    {
        "tag": "Proxy",
        "type": "hysteria2",
        "server": "$X_SERVER",
        "server_port": $X_PORT,
        "up_mbps": 100,
        "down_mbps": 100,
        "password": "$X_AUTH",
        "connect_timeout": "5s",
        "tcp_fast_open": true,
        "udp_fragment": true,
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
    PROXY_PART=""
fi

MAIN_PART=$(cat <<EOF
{
    "log": {
        "level": "warn",
        "timestamp": true
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "store_rdrc": true
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "remote",
                "address": "https://1.0.0.1/dns-query",
                "address_resolver": "local",
                "client_subnet": "1.0.1.0",
                "detour": "Proxy"
            },
            {
                "tag": "local",
                "address": "udp://119.29.29.29",
                "detour": "direct-out"
            }
        ],
"rules": [
            {
                "outbound": "any",
                "server": "local",
                "action": "route"
            },
            {
                "action": "route-options",
                "domain": [
                    "*"
                ],
                "rewrite_ttl": 64,
                "udp_connect": false,
                "udp_disable_domain_unmapping": false
            },
            {
                "rule_set": "geosite-geolocation-cn",
                "server": "local",
                "action": "route"
            },
            {
                "type": "logical",
                "mode": "and",
                "rules": [
                    {
                        "rule_set": "geosite-geolocation-!cn",
                        "invert": true
                    },
                    {
                        "rule_set": "geoip-cn"
                    }
                ],
                "server": "remote",
                "client_subnet": "114.114.114.114/24"
            }
        ],
        "strategy": "ipv4_only",
        "final": "remote",
        "reverse_mapping": true,
        "disable_cache": false,
        "disable_expire": false
    },
    "inbounds": [
        {
            "type": "tproxy",
            "tag": "tp-in",
            "listen": "::",
            "listen_port": 60091,
            "udp_fragment": true,
            "tcp_fast_open": true,
            "tcp_multi_path": false,
            "udp_timeout": "5m",
        }
    ],
    "outbounds": [
$PROXY_PART,
        {
            "tag": "direct-out",
            "type": "direct",
            "udp_fragment": true
        }
    ],
    "route": {
        "final": "Proxy",
        "auto_detect_interface": true,
        "rules": [
            {
                "inbound": "tun-in",
                "action": "sniff"
            },
            {
                "protocol": "dns",
                "action": "hijack-dns"
            },
            {
                "protocol": ["quic", "BitTorrent"],
                "action": "reject"
            },
            {
                "rule_set": [
                    "geoip-cn",
                    "geosite-geolocation-cn"
                ],
                "outbound": "direct-out"
            },
            {
                "ip_is_private": true,
                "outbound": "direct-out"
            },
            {
                "ip_cidr": [
                    "0.0.0.0/8",
                    "10.0.0.0/8",
                    "127.0.0.0/8",
                    "169.254.0.0/16",
                    "172.16.0.0/12",
                    "192.168.0.0/16",
                    "224.0.0.0/4",
                    "240.0.0.0/4",
                    "52.80.0.0/16"
                ],
                "outbound": "direct-out"
            },
            {
                "rule_set": "geosite-geolocation-!cn",
                "outbound": "Proxy"
            }
        ],
        "rule_set": [
            {
                "tag": "geosite-geolocation-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://testingcf.jsdelivr.net/gh/lyc8503/sing-box-rules@rule-set-geosite/geosite-geolocation-cn.srs",
                "download_detour": "direct-out"
            },
            {
                "tag": "geosite-geolocation-!cn",
                "type": "remote",
                "format": "binary",
                "url": "https://testingcf.jsdelivr.net/gh/lyc8503/sing-box-rules@rule-set-geosite/geosite-geolocation-!cn.srs",
                "download_detour": "direct-out"
            },
            {
                "tag": "geosite-category-ads-all",
                "type": "remote",
                "format": "binary",
                "url": "https://testingcf.jsdelivr.net/gh/lyc8503/sing-box-rules@rule-set-geosite/geosite-category-ads-all.srs",
                "download_detour": "direct-out"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://testingcf.jsdelivr.net/gh/lyc8503/sing-box-rules@rule-set-geoip/geoip-cn.srs",
                "download_detour": "direct-out"
            }
        ]
    }
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