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
        "level": "warn",
        "timestamp": true
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "store_fakeip": true,
            "store_rdrc": true
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "google",
                "address": "https://dns.google/dns-query",
                "address_resolver": "dns-direct",
                "client_subnet": "1.0.1.0",
                "detour": "Proxy"
            },
            {
                "tag": "dns-direct",
                "address": "https://120.53.53.53/dns-query",
                "detour": "direct-out"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "dns-direct",
                "action": "route"
            },
            {
                "rule_set": "geosite-geolocation-cn",
                "server": "dns-direct",
                "action": "route"
            }
        ],
        "final": "google",
        "reverse_mapping": true,
        "disable_cache": false,
        "disable_expire": false
    },
    "route": {
        "final": "Proxy",
        "auto_detect_interface": true,
        "rules": [
            {
                "inbound": "tp-in",
                "action": "sniff"
            },
            {
                "protocol": "dns",
                "action": "hijack-dns"
            },
            {
                "rule_set": "geosite-geolocation-!cn",
                "outbound": "Proxy"
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