#!/bin/bash

PUSH_URL="https://uptime.leblais.net/api/push/Hbl8JKsGDB"

# Vérifier status Nextcloud
STATUS=$(curl -s https://cloud.leblais.net/status.php)

# Vérifier RAM
RAM_AVAILABLE=$(free -m | awk 'NR==2 {print $7}')

# Vérifier si un cron tourne depuis trop longtemps (>15 min)
CRON_BLOCKED=0
CRON_PID=$(pgrep -f "cron.php" 2>/dev/null)
if [ ! -z "$CRON_PID" ]; then
    # Vérifier depuis combien de temps (en secondes)
    ELAPSED=$(ps -o etimes= -p $CRON_PID 2>/dev/null | tr -d ' ')
    if [ ! -z "$ELAPSED" ] && [ "$ELAPSED" -gt 900 ]; then
        CRON_BLOCKED=1
        CRON_RUNNING="${ELAPSED}s"
    fi
fi


# Décision finale
if echo "$STATUS" | grep -q '"installed":true'; then
    if [ "$CRON_BLOCKED" -eq 1 ]; then
        # Cron bloqué détecté
        curl -s -G "${PUSH_URL}" \
            --data-urlencode "status=down" \
            --data-urlencode "msg=⚠️ Cron bloqué depuis ${CRON_RUNNING}" > /dev/null
    elif [ "$RAM_AVAILABLE" -lt 200 ]; then
        # RAM critique
        curl -s -G "${PUSH_URL}" \
            --data-urlencode "status=down" \
            --data-urlencode "msg=⚠️ RAM critique: ${RAM_AVAILABLE}MB" > /dev/null
    else
        # Tout OK
        curl -s -G "${PUSH_URL}" \
            --data-urlencode "status=up" \
            --data-urlencode "msg=Nextcloud OK - RAM: ${RAM_AVAILABLE}MB" > /dev/null
    fi
else
    # Nextcloud inaccessible
    curl -s -G "${PUSH_URL}" \
        --data-urlencode "status=down" \
        --data-urlencode "msg=❌ Nextcloud inaccessible" > /dev/null
fi
