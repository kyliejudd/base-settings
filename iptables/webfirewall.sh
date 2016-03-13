#!/usr/bin/env bash
IPT=/usr/sbin/iptables

#Home address
HOSTNAME=<REDACTED>
HOME=$(host $HOSTNAME | grep -iE "[1-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)

#work address
WORK=<REDACTED>,<REDACTED>
#others
OTHER=<REDACTED>

ALLOW_IP=$WORK,$OTHER

#allowed port e.g. ssh
ALLOW_PORTS=<REDACTED>

# Clear ALL iptables settings
$IPT -F
$IPT -X

$IPT -P INPUT DROP
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT

#talking to yourself is lonely
$IPT -A INPUT -i lo -j ACCEPT

#new chains
$IPT -N home
$IPT -N log-and-drop
#new chains to throttle connections
$IPT -N traffic_throttle
$IPT -N recent_limit



#accept packets for already established connections
$IPT -A INPUT -s 0/0 -m state --state RELATED,ESTABLISHED -j ACCEPT
# add rate limited connections 
iptables -A recent_limit -m recent --name input_trap --rcheck --seconds 60 --hitcount 10 --rttl -j DROP
#limit of 6 connections from the same IP
iptables -A traffic_throttle -m connlimit --connlimit-above 6 -j DROP

#add rule to the home chain to accept anything from home
$IPT -A home -s $HOME -j ACCEPT 
#send packets to the home chain
$IPT -A INPUT -j home

iptables -A recent_limit -m recent --name input_trap --set -j RETURN
iptables -A INPUT -s 0/0 -p TCP -m multiport --dports $ALLOW_PORTS --syn -j traffic_throttle
iptables -A traffic_throttle -m limit --limit 6/m --limit-burst 1 -j ACCEPT

#allow other IP on restricted ports
$IPT -A INPUT -s $ALLOW_IP -p tcp --dport $ALLOW_PORTS -j ACCEPT

# drop verbose before logging
$IPT -A INPUT -p udp -m multiport --dports 137,67,138 -j DROP

$IPT -A INPUT -s 10.0.0.0/8       -j DROP								# (Spoofed network)
$IPT -a INPUT -s 192.0.0.1/24     -j DROP								# (Spoofed network)
$IPT -A INPUT -s 169.254.0.0/16   -j DROP								# (Spoofed network)
$IPT -A INPUT -s 172.16.0.0/12    -j DROP								# (Spoofed network)
$IPT -A INPUT -s 224.0.0.0/4      -j DROP								# (Spoofed network)
$IPT -A INPUT -d 224.0.0.0/4      -j DROP								# (Spoofed network)
$IPT -A INPUT -s 240.0.0.0/5      -j DROP								# (Spoofed network)
$IPT -A INPUT -d 240.0.0.0/5      -j DROP								# (Spoofed network)
$IPT -A INPUT -s 0.0.0.0/8        -j DROP								# (Spoofed network)
$IPT -A INPUT -d 0.0.0.0/8        -j DROP								# (Spoofed network)
$IPT -A INPUT -d 239.255.255.0/24 -j DROP								# (Spoofed network)
$IPT -A INPUT -d 255.255.255.255  -j DROP			

#send packets to log and drop chain
$IPT -A INPUT -j log-and-drop
$IPT -A log-and-drop -j LOG --log-prefix 'IPTABLES-BLOCKED'
$IPT -A INPUT -j DROP
