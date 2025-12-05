#!/bin/bash
# Check VPN status via qBittorrent Docker container
# Pour sonde Uptime Kuma Push

CONTAINER_NAME="qbittorrent"
UPTIME_PUSH_URL="https://uptime.leblais.net/api/push/Nq3MMbgPkd"

# Récupérer l'IP du container
CURRENT_IP=$(docker exec "$CONTAINER_NAME" curl -s --max-time 10 ifconfig.me 2>/dev/null)

if [ -z "$CURRENT_IP" ]; then
    echo "ERREUR - Impossible de récupérer l'IP du container"
    curl -s "${UPTIME_PUSH_URL}?status=down&msg=NO_IP"
    exit 1
fi

# Vérifier que ce n'est PAS notre IP Free (commence par 2a01:e0a pour IPv6 ou ton IPv4)
# On vérifie simplement que l'IP est différente de l'IP du serveur
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null)

if [ "$CURRENT_IP" = "$SERVER_IP" ]; then
    echo "ERREUR - VPN DOWN : même IP que le serveur ($CURRENT_IP)"
    curl -s "${UPTIME_PUSH_URL}?status=down&msg=VPN_DOWN"
    exit 1
fi

# Vérifier que l'IP est bien une IP VPN connue (optionnel)
# WorldStream NL: 185.132.178.x ou autres ranges VPN
echo "OK - VPN actif : $CURRENT_IP"
curl -s "${UPTIME_PUSH_URL}?status=up&msg=VPN_OK&ping="
exit 0
