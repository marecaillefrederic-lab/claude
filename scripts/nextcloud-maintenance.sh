#!/bin/bash

# Script de maintenance mensuelle Nextcloud
LOGFILE="/var/log/nextcloud-maintenance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
PUSH_URL="https://uptime.leblais.net/api/push/cV8ziWEEQ7"
ERROR=0

echo "=========================================" >> "$LOGFILE"
echo "Maintenance Nextcloud - $DATE" >> "$LOGFILE"
echo "=========================================" >> "$LOGFILE"

# 1. Nettoyer fichiers orphelins
echo "1. Nettoyage fichiers orphelins..." >> "$LOGFILE"
if ! sudo -u www-data php /var/www/nextcloud/occ files:cleanup >> "$LOGFILE" 2>&1; then
    ERROR=1
fi

# 2. Optimiser base de données
echo "2. Optimisation PostgreSQL..." >> "$LOGFILE"
if ! sudo -u postgres psql -d nextcloud -c "VACUUM ANALYZE;" >> "$LOGFILE" 2>&1; then
    ERROR=1
fi

# 3. État RAM
echo "3. État RAM après maintenance :" >> "$LOGFILE"
free -h >> "$LOGFILE"

# 4. Espace disque
echo "4. Espace disque :" >> "$LOGFILE"
df -h /mnt/datadisk >> "$LOGFILE"

# Notification Uptime Kuma
if [ $ERROR -eq 0 ]; then
    curl -s -G "${PUSH_URL}" \
        --data-urlencode "status=up" \
        --data-urlencode "msg=Maintenance mensuelle OK" > /dev/null
else
    curl -s -G "${PUSH_URL}" \
        --data-urlencode "status=down" \
        --data-urlencode "msg=⚠️ Erreur maintenance" > /dev/null
fi

echo "=========================================" >> "$LOGFILE"
echo "Maintenance terminée - $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
echo "" >> "$LOGFILE"
