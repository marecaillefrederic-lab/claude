#!/bin/bash

# Script de vérification des mises à jour Nextcloud
# Utilise l'updater server officiel de Nextcloud

PUSH_URL="https://uptime.leblais.net/api/push/hHVyPCGbPF"

# Récupérer la version actuelle
CURRENT_VERSION=$(sudo -u www-data php /var/www/nextcloud/occ status --output=json 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CURRENT_VERSION" ]; then
    # Fallback si la commande échoue
    CURRENT_VERSION=$(grep "VersionString = " /var/www/nextcloud/version.php | cut -d"'" -f2)
fi

# Interroger l'updater server de Nextcloud
# Format: https://updates.nextcloud.com/updater_server/?version=25.0.1
UPDATE_INFO=$(curl -s "https://updates.nextcloud.com/updater_server/?version=${CURRENT_VERSION}" 2>/dev/null)

# Vérifier si une mise à jour est disponible
if echo "$UPDATE_INFO" | grep -q "<version>"; then
    # Une mise à jour est disponible
    NEW_VERSION=$(echo "$UPDATE_INFO" | grep -oP '<version>\K[^<]+' | head -1)
    MESSAGE="⚠️ Mise à jour disponible: ${CURRENT_VERSION} → ${NEW_VERSION}"
    
    # Push avec status=down pour notification
    curl -s -G "${PUSH_URL}" \
        --data-urlencode "status=down" \
        --data-urlencode "msg=${MESSAGE}" > /dev/null
    
    echo "$(date): Update available - ${MESSAGE}" >> /var/log/nextcloud-updates.log
else
    # Aucune mise à jour disponible
    curl -s -G "${PUSH_URL}" \
        --data-urlencode "status=up" \
        --data-urlencode "msg=Nextcloud ${CURRENT_VERSION} à jour" > /dev/null
    
    echo "$(date): Nextcloud ${CURRENT_VERSION} is up to date" >> /var/log/nextcloud-updates.log
fi
