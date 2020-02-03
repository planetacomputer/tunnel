#!/bin/bash
ip route del default
ip route add default via 10.6.0.6
iptables -A INPUT -p icmp --icmp-type any -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type any -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type any -j ACCEPT
