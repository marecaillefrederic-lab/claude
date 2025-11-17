#!/bin/bash

# Script de maintenance mensuelle Nextcloud
# À exécuter via cron le 1er de chaque mois à 3h du matin

LOGFILE="/var/log/nextcloud-maintenance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=========================================" >> "$LOGFILE"
echo "Maintenance Nextcloud - $DATE" >> "$LOGFILE"
echo "=========================================" >> "$LOGFILE"

# 1. Nettoyer fichiers orphelins
echo "1. Nettoyage fichiers orphelins..." >> "$LOGFILE"
sudo -u www-data php /var/www/nextcloud/occ files:cleanup >> "$LOGFILE" 2>&1

# 2. Optimiser base de données
echo "2. Optimisation PostgreSQL..." >> "$LOGFILE"
sudo -u postgres psql -d nextcloud -c "VACUUM ANALYZE;" >> "$LOGFILE" 2>&1

# 3. Vérifier intégrité fichiers (optionnel, long)
# echo "3. Vérification intégrité..." >> "$LOGFILE"
# sudo -u www-data php /var/www/nextcloud/occ files:scan --all >> "$LOGFILE" 2>&1

# 4. État RAM
echo "4. État RAM après maintenance :" >> "$LOGFILE"
free -h >> "$LOGFILE"

# 5. Espace disque
echo "5. Espace disque :" >> "$LOGFILE"
df -h /mnt/WD_Freebox >> "$LOGFILE"

# Ajouter à la fin (avant dernière ligne) :
PUSH_URL_MAINTENANCE="https://uptime.leblais.net/api/push/cV8ziWEEQ7?status=up&msg=OK&ping="

# Si maintenance OK
if [ $? -eq 0 ]; then
    curl -s "${PUSH_URL_MAINTENANCE}?status=up&msg=Maintenance%20mensuelle%20OK" > /dev/null
else
    curl -s "${PUSH_URL_MAINTENANCE}?status=down&msg=Erreur%20maintenance" > /dev/null
fi

echo "=========================================" >> "$LOGFILE"
echo "Maintenance terminée - $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Notifier Uptime Kuma (optionnel)
# curl "https://uptime.leblais.net/api/push/PUSH_KEY?status=up&msg=Maintenance%20Nextcloud%20OK"
