#!/bin/sh

set -e

corepack enable && corepack prepare yarn@stable --activate

sleep 5

_X_SERVER=example.com
_X_PORT=443
_X_AUTH=passwd

X_SERVER="${X_SERVER:-$_X_SERVER}"
X_PORT="${X_PORT:-$_X_PORT}"
X_AUTH="${X_AUTH:-$_X_AUTH}"

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
        "disabled": false,
        "level": "debug",
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
                "tag": "ND-h3",
                "address": "h3://dns.nextdns.io/x",
                "address_resolver": "dns-direct",
                "detour": "direct-out"
            },
            {
                "tag": "dns-direct",
                "address": "udp://223.5.5.5",
                "detour": "direct-out"
            }
        ],
        "strategy": "ipv4_only",
        "final": "ND-h3",
        "reverse_mapping": true,
        "disable_cache": false,
        "disable_expire": false
    },
    "route": {
        "rules": [
            {
                "inbound": "tp-in",
                "action": "sniff",
                "sniffer": [
                    "dns",
                    "bittorrent",
                    "http",
                    "tls",
                    "quic",
                    "dtls"
                ]
            },
            {
                "protocol": "dns",
                "action": "hijack-dns"
            },
            {
                "ip_is_private": true,
                "action": "route",
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
                "action": "route",
                "outbound": "direct-out"
            }
        ],
        "auto_detect_interface": true,
        "final": "Proxy"
    },
    "outbounds": [
$PROXY_PART,
        {
            "tag": "direct-out",
            "type": "direct",
            "udp_fragment": true
        }
    ],
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
            "domain_strategy": "prefer_ipv4"
        }
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

if [ ! -e "/usr/bin/dev-cli" ]; then
    echo "sing-box -c /etc/sing-box/x.json run" > /usr/bin/dev-cli && chmod +x /usr/bin/dev-cli
fi

exec "$@"