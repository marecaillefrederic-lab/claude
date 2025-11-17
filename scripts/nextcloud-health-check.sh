#!/bin/bash

PUSH_URL="https://uptime.leblais.net/api/push/Hbl8JKsGDB?status=up&msg=OK&ping="

# Vérifier status Nextcloud
STATUS=$(curl -s https://cloud.leblais.net/status.php)

if echo "$STATUS" | grep -q '"installed":true'; then
    # Vérifier RAM
    RAM_AVAILABLE=$(free -m | awk 'NR==2 {print $7}')
    
    if [ "$RAM_AVAILABLE" -lt 200 ]; then
        # RAM critique
        curl -s "${PUSH_URL}?status=down&msg=RAM%20critique:%20${RAM_AVAILABLE}MB" > /dev/null
    else
        # Tout OK
        curl -s "${PUSH_URL}?status=up&msg=Nextcloud%20OK%20-%20RAM:%20${RAM_AVAILABLE}MB" > /dev/null
    fi
else
    # Nextcloud down
    curl -s "${PUSH_URL}?status=down&msg=Nextcloud%20inaccessible" > /dev/null
fi

# Vérifier si un cron tourne depuis trop longtemps (>15 min = 900s)
CRON_RUNNING=$(ps -eo pid,etime,cmd | grep "nextcloud/cron.php" | grep -v grep | awk '{print $2}')

if [ ! -z "$CRON_RUNNING" ]; then
    # Convertir le temps en secondes (format MM:SS ou HH:MM:SS)
    # Si > 15 min, alerter
    echo "Warning: Nextcloud cron running for $CRON_RUNNING"
fi
