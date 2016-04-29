#!/usr/bin/env bash
#redhat/centos
IPT=/usr/sbin/iptables
#debian/ubuntu
IPT=/sbin/iptables

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

#add rule to the home chain to accept anything from home
$IPT -A home -s $HOME -j ACCEPT

#accept packets for already established connections
$IPT -A INPUT -s 0/0 -m state --state RELATED,ESTABLISHED -j ACCEPT

#send packets to the home chain
$IPT -A INPUT -j home

#allow other IP on restricted ports
$IPT -A INPUT -s $ALLOW_IP -p tcp --dport $ALLOW_PORTS -j ACCEPT

# drop verbose before logging
$IPT -A INPUT -p udp -m multiport --dports 137,67,138 -j DROP

#send packets to log and drop chain
$IPT -A INPUT -j log-and-drop
$IPT -A log-and-drop -j LOG --log-prefix 'IPTABLES-BLOCKED'
$IPT -A INPUT -j DROP
