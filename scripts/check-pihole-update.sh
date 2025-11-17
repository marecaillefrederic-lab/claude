#!/bin/bash

# ============================================
# Script de vérification des mises à jour Pi-hole
# Envoie une notification à Uptime Kuma si MAJ disponible
# ============================================

# URL Push Uptime Kuma (à remplacer par la tienne)
UPTIME_PUSH_URL="https://uptime.leblais.net/api/push/FQd5HEJnWf"

# Fonction pour envoyer une notification à Uptime Kuma
send_notification() {
    local status=$1
    local message=$2
curl -fsS -m 10 --retry 3 \
        -G --data-urlencode "status=${status}" \
        --data-urlencode "msg=${message}" \
        "${UPTIME_PUSH_URL}" \
        > /dev/null 2>&1   
}

# Vérifier les versions
VERSION_OUTPUT=$(pihole -v 2>&1)

# Extraire les informations (nettoyer parenthèses)
CORE_UPDATE=$(echo "$VERSION_OUTPUT" | grep "Core" | grep -o "Latest:.*" | awk '{print $2}' | tr -d '()')
WEB_UPDATE=$(echo "$VERSION_OUTPUT" | grep "Web" | grep -o "Latest:.*" | awk '{print $2}' | tr -d '()')
FTL_UPDATE=$(echo "$VERSION_OUTPUT" | grep "FTL" | grep -o "Latest:.*" | awk '{print $2}' | tr -d '()')

CORE_CURRENT=$(echo "$VERSION_OUTPUT" | grep "Core" | grep -o "version is.*" | awk '{print $3}' | tr -d '()')
WEB_CURRENT=$(echo "$VERSION_OUTPUT" | grep "Web" | grep -o "version is.*" | awk '{print $3}' | tr -d '()')
FTL_CURRENT=$(echo "$VERSION_OUTPUT" | grep "FTL" | grep -o "version is.*" | awk '{print $3}' | tr -d '()')


# Vérifier si des mises à jour sont disponibles
UPDATES_AVAILABLE=false
UPDATE_MESSAGE=""

if [ "$CORE_CURRENT" != "$CORE_UPDATE" ] && [ "$CORE_UPDATE" != "null" ]; then
    UPDATES_AVAILABLE=true
    UPDATE_MESSAGE="${UPDATE_MESSAGE}Core: $CORE_CURRENT -> $CORE_UPDATE | "
fi

if [ "$WEB_CURRENT" != "$WEB_UPDATE" ] && [ "$WEB_UPDATE" != "null" ]; then
    UPDATES_AVAILABLE=true
    UPDATE_MESSAGE="${UPDATE_MESSAGE}Web: $WEB_CURRENT -> $WEB_UPDATE | "
fi

if [ "$FTL_CURRENT" != "$FTL_UPDATE" ] && [ "$FTL_UPDATE" != "null" ]; then
    UPDATES_AVAILABLE=true
    UPDATE_MESSAGE="${UPDATE_MESSAGE}FTL: $FTL_CURRENT -> $FTL_UPDATE"
fi

# Envoyer la notification
if [ "$UPDATES_AVAILABLE" = true ]; then
    send_notification "down" "Pi-hole MAJ disponible: ${UPDATE_MESSAGE}"
    echo "✉️ Notification envoyée: Mise à jour disponible"
    exit 1
else
    send_notification "up" "Pi-hole à jour (Core: $CORE_CURRENT, Web: $WEB_CURRENT, FTL: $FTL_CURRENT)"
    echo "✅ Pi-hole est à jour"
    exit 0
fi
