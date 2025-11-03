#!/bin/bash

# Supprimer le namespace s'il existe déjà (au cas où)
ip netns del vpn 2>/dev/null

# Créer le namespace
ip netns add vpn

# Supprimer les interfaces si elles existent
ip link del veth0 2>/dev/null

# Créer les interfaces virtuelles
ip link add veth0 type veth peer name veth1
ip link set veth1 netns vpn

# Configurer veth0 (côté hôte)
ip addr add 10.200.200.1/24 dev veth0
ip link set veth0 up

# Configurer veth1 (côté namespace)
ip netns exec vpn ip addr add 10.200.200.2/24 dev veth1
ip netns exec vpn ip link set veth1 up
ip netns exec vpn ip link set lo up

echo "Namespace VPN configuré avec succès"
