#!/bin/bash

# Lancer OpenVPN dans le namespace vpn
ip netns exec vpn openvpn --config /etc/openvpn/protonvpn/pl-free-13.protonvpn.udp.ovpn --daemon --log /var/log/openvpn-vpn-namespace.log

# Attendre que tun0 soit créé dans le namespace
sleep 5

# Configurer le routage dans le namespace
ip netns exec vpn ip route add default via 10.200.200.1

# Configurer NAT pour router le trafic du namespace vers tun0
# Note: tun0 est dans le namespace, donc on doit faire le NAT correctement

# Activer le forwarding entre veth0 et le namespace
iptables -A FORWARD -i veth0 -j ACCEPT
iptables -A FORWARD -o veth0 -j ACCEPT

# NAT pour le trafic sortant du namespace
iptables -t nat -A POSTROUTING -s 10.200.200.0/24 ! -d 10.200.200.0/24 -j MASQUERADE

echo "OpenVPN démarré dans le namespace vpn"
