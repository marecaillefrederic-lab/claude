#!/bin/bash

# Script de vérification des mises à jour Nextcloud
# Push vers Uptime Kuma si update disponible

PUSH_URL="https://uptime.leblais.net/api/push/hHVyPCGbPF?status=up&msg=OK&ping="

# Vérifier updates Nextcloud
UPDATE_CHECK=$(sudo -u www-data php /var/www/nextcloud/occ update:check 2>&1)

if echo "$UPDATE_CHECK" | grep -q "update available"; then
    # Extraire version disponible
    NEW_VERSION=$(echo "$UPDATE_CHECK" | grep -oP 'Nextcloud \K[0-9.]+' | head -1)
    CURRENT_VERSION=$(sudo -u www-data php /var/www/nextcloud/occ status | grep "version:" | awk '{print $3}')
    
    MESSAGE="⚠️ Mise à jour Nextcloud disponible: $CURRENT_VERSION → $NEW_VERSION"
    
    # Push vers Uptime Kuma avec status=down pour notification
    curl -s "${PUSH_URL}?status=down&msg=${MESSAGE}" > /dev/null
    
    echo "$(date): Update available - $MESSAGE" >> /var/log/nextcloud-updates.log
else
    # Tout est à jour
    curl -s "${PUSH_URL}?status=up&msg=Nextcloud%20à%20jour" > /dev/null
    echo "$(date): Nextcloud is up to date" >> /var/log/nextcloud-updates.log
fi
