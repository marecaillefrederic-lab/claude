#!/bin/bash
# ============================================
# Script de synchronisation automatique du repo GitHub claude
# Adapté pour Trigkey N150
# ============================================

# Configuration
CLAUDE_DIR="/home/frederic/claude"
LOG_FILE="/var/log/sync-claude-repo.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Fonction de log
log() {
    echo "[$DATE] $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "Début synchronisation repo claude"

# Aller dans le repo
cd "$CLAUDE_DIR" || exit 1

# 1. Copier les configs
log "Copie des configurations..."
mkdir -p configs/caddy configs/authelia configs/fail2ban/filter.d configs/pihole

cp /etc/caddy/Caddyfile configs/caddy/ 2>/dev/null
cp /etc/authelia/configuration.yml configs/authelia/ 2>/dev/null
cp /etc/fail2ban/jail.local configs/fail2ban/ 2>/dev/null
cp /etc/fail2ban/filter.d/caddy-*.conf configs/fail2ban/filter.d/ 2>/dev/null
cp /etc/fail2ban/filter.d/fail2ban-stats.conf configs/fail2ban/filter.d/ 2>/dev/null

# 2. Copier les scripts
log "Copie des scripts..."
mkdir -p scripts

cp /usr/local/bin/check-*.sh scripts/ 2>/dev/null
cp /usr/local/bin/nextcloud-*.sh scripts/ 2>/dev/null
cp /usr/local/bin/backup-trigkey.sh scripts/ 2>/dev/null
cp /usr/local/bin/update-geoip.sh scripts/ 2>/dev/null
cp /usr/local/bin/sync-claude-repo.sh scripts/ 2>/dev/null

# 3. Copier les docker-compose
log "Copie des docker-compose..."
mkdir -p docker-compose

for dir in /opt/*/; do
    service=$(basename "$dir")
    if [ -f "$dir/docker-compose.yml" ]; then
        cp "$dir/docker-compose.yml" docker-compose/"$service".yml 2>/dev/null
    fi
done

# 4. Copier les apps web (sans données sensibles)
log "Copie des apps web..."
mkdir -p web/workout web/vault web/fail2ban-stats

# Workout (sans data/)
cp /var/www/workout/*.html web/workout/ 2>/dev/null
cp /var/www/workout/*.css web/workout/ 2>/dev/null
cp /var/www/workout/*.js web/workout/ 2>/dev/null
cp /var/www/workout/*.php web/workout/ 2>/dev/null

# Vault
cp /var/www/vault/*.html web/vault/ 2>/dev/null
cp /var/www/vault/*.css web/vault/ 2>/dev/null

# Fail2ban stats (script seulement)
cp /var/www/fail2ban-stats/generate_stats.py web/fail2ban-stats/ 2>/dev/null

# 5. Exporter crontabs
log "Export crontabs..."
mkdir -p configs/crontabs
crontab -l > configs/crontabs/root.txt 2>/dev/null
sudo -u frederic crontab -l > configs/crontabs/frederic.txt 2>/dev/null

# 6. Corriger les permissions
chown -R frederic:frederic "$CLAUDE_DIR"

# 7. Vérifier s'il y a des changements
cd "$CLAUDE_DIR"
if git status --porcelain | grep -q .; then
    log "Changements détectés, commit en cours..."
    
    # Ajouter tous les changements
    sudo -u frederic git add -A
    
    # Créer commit avec liste des fichiers modifiés
    CHANGES=$(git status --short | wc -l)
    sudo -u frederic git commit -m "Auto-sync: $CHANGES fichier(s) modifié(s) le $(date '+%d/%m/%Y à %H:%M')"
    
    # Push vers GitHub
    if sudo -u frederic git push origin main; then
        log "✅ Push réussi vers GitHub"
    else
        log "❌ Erreur lors du push"
        exit 1
    fi
else
    log "Aucun changement détecté"
fi

log "Synchronisation terminée avec succès"
log "========================================="
