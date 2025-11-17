#!/bin/bash
# Nextcloud - Cleanup des verrous expirés
# Empêche l'accumulation de verrous qui bloquent les crons

LOCKS_DELETED=$(sudo -u postgres psql -d nextcloud -t -c "DELETE FROM oc_file_locks WHERE ttl < EXTRACT(EPOCH FROM NOW()); SELECT ROW_COUNT();" 2>/dev/null | tr -d ' ')

JOBS_FREED=$(sudo -u postgres psql -d nextcloud -t -c "UPDATE oc_jobs SET reserved_at = 0 WHERE reserved_at > 0; SELECT ROW_COUNT();" 2>/dev/null | tr -d ' ')

# Log uniquement si des verrous ont été supprimés
if [ "$LOCKS_DELETED" -gt 0 ] || [ "$JOBS_FREED" -gt 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Locks deleted: $LOCKS_DELETED, Jobs freed: $JOBS_FREED" >> /var/log/nextcloud-cleanup.log
    
    # Push vers Uptime Kuma si problème important
    if [ "$LOCKS_DELETED" -gt 100 ]; then
        curl -s "https://uptime.leblais.net/api/push/XXX?status=up&msg=Cleanup_${LOCKS_DELETED}_locks"
    fi
fi
