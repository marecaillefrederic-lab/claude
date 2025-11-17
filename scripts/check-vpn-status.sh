#!/bin/bash

# IP attendue (serveur polonais ProtonVPN)
EXPECTED_IP="149.102.244"

# Vérifier l'IP dans le namespace
CURRENT_IP=$(sudo ip netns exec vpn curl -s --max-time 5 ifconfig.me 2>/dev/null)

if [[ $CURRENT_IP == $EXPECTED_IP* ]]; then
    echo "OK - VPN actif : $CURRENT_IP"
    exit 0
else
    echo "ERREUR - VPN down ou mauvaise IP : $CURRENT_IP"
    # Optionnel : redémarrer automatiquement
    sudo systemctl restart protonvpn-namespace
    exit 1
fi
