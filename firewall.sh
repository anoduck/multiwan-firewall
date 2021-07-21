#!/usr/bin/env bash
# --------------------------------------------------------------------------------------
# Most of this was derived from:
# https://sagar.se/2020/11/01/diy-multi-wan-linux-router-part-2/#Multi-WAN_load_balancing_and_failover
# https://askubuntu.com/questions/557085/how-to-setup-ubuntu-router-with-2-wan-interfaces
# ========================================================================================

# !! > BE SURE TO FILL THESE OUT WITH THE APPROPRIATE VALUES! < !! #
LAN_IFACE="Lan interface"
WAN1_IFACE="First Wan Interface"
WAN2_IFACE="Second Wan Interface"
# The following values will more than likely be something like:
# Ex. "192.168.1.0/24" or "10.0.0.0/24"
WAN1_NET="First Wan Network"
WAN2_NET="Second Wan Network"
LAN_NET="Lan Network"
# Gateways
WAN1_GW="Wan 1 Gateway"
WAN2_GW="Wan 2 Gateway"

# Addresses
WAN1_ADDR="Wan 1 interface address"
WAN2_ADDR="Wan 2 interface address"

# Enable IPv4 forwarding
#echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# ----------------------------------------------------
# Firewall
# ----------------------------------------------------

# Start from a blank slate. Flush all iptables rules
iptables -F
iptables -X
iptables -Z

# Default policy to drop all incoming and forwarded packets.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Accept incoming packets from localhost and the LAN interface.
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i $LAN_IFACE -j ACCEPT

# Accept incoming packets from the WAN if the router initiated the connection.
iptables -A INPUT -i $WAN1_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i $WAN2_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Accept forwarded packets from LAN to the WAN.
iptables -A FORWARD -i $LAN_IFACE -o $WAN1_IFACE -j ACCEPT
iptables -A FORWARD -i $LAN_IFACE -o $WAN2_IFACE -j ACCEPT

# Accept forwarded packets from WAN to the LAN if the LAN initiated the connection.
iptables -A FORWARD -i $WAN1_IFACE -o $LAN_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i $WAN2_IFACE -o $LAN_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# NAT traffic going out the WAN.
iptables -t nat -A POSTROUTING -o $WAN1_IFACE -j MASQUERADE
iptables -t nat -A POSTROUTING -o $WAN2_IFACE -j MASQUERADE
# -----------------------------------------------------------

# Setup
ip route del default table main
ip route add default via $WAN1_GW dev $WAN1_IFACE table main

# Table 1
ip route add $WAN1_NET dev $WAN1_IFACE src $WAN1_ADDR table 1
ip route add default via $WAN1_GW dev $WAN1_IFACE table 1
ip route add $LAN_NET dev $LAN_IFACE table 1
ip route add $WAN2_NET dev $WAN2_IFACE table 1
ip route add 127.0.0.0/8 dev lo table 1

# Table 2
ip route add $WAN2_NET dev $WAN2_IFACE src $WAN2_ADDR table 2
ip route add default via $WAN2_GW dev $WAN2_IFACE table 2
ip route add $LAN_NET dev $LAN_IFACE table 2
ip route add $WAN1_NET dev $WAN1_IFACE table 2
ip route add 127.0.0.0/8 dev lo table 2

ip rule add from $WAN1_ADDR table 1
ip rule add from $WAN2_ADDR table 2

# ===========================================================
exit 0
