#!/bin/bash
# Backup complet Trigkey - leblais.net
# Destination : VPS OVH via SSH
# Exclut les données Nextcloud (backup séparé sur USB)

# Configuration
VPS_HOST="vps"  # Utilise ~/.ssh/config
VPS_USER="debian"
VPS_BACKUP_DIR="/home/debian/backups/trigkey"
LOCAL_BACKUP_DIR="/tmp/backup-trigkey"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_trigkey_${DATE}"
TEMP_DIR="${LOCAL_BACKUP_DIR}/${BACKUP_NAME}"
LOG_FILE="/var/log/backup-trigkey.log"
RETENTION_DAYS=30

# Couleurs pour les logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Fonction de log
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓${NC} $1"
}

log_warning() {
    log "${YELLOW}⚠${NC} $1"
}

log_error() {
    log "${RED}✗${NC} $1"
}

# Création des répertoires
mkdir -p "$LOCAL_BACKUP_DIR"
mkdir -p "$TEMP_DIR"

log "=========================================="
log "=== Début du backup Trigkey leblais.net ==="
log "=========================================="

# 1. Configurations système de base
log "📦 Backup configurations système..."
mkdir -p "$TEMP_DIR/etc"

# Caddy
if [ -d /etc/caddy ]; then
    cp -r /etc/caddy "$TEMP_DIR/etc/" 2>/dev/null && log_success "Caddy"
fi

# Fail2ban
if [ -d /etc/fail2ban ]; then
    cp -r /etc/fail2ban "$TEMP_DIR/etc/" 2>/dev/null && log_success "Fail2ban"
fi

# WireGuard
if [ -d /etc/wireguard ]; then
    cp -r /etc/wireguard "$TEMP_DIR/etc/" 2>/dev/null && log_success "WireGuard"
fi

# SSH
if [ -f /etc/ssh/sshd_config ]; then
    mkdir -p "$TEMP_DIR/etc/ssh"
    cp /etc/ssh/sshd_config "$TEMP_DIR/etc/ssh/" 2>/dev/null && log_success "SSH config"
fi

# fstab
if [ -f /etc/fstab ]; then
    cp /etc/fstab "$TEMP_DIR/etc/" 2>/dev/null && log_success "fstab"
fi

# 2. Authelia
log "🔐 Backup Authelia..."
if [ -d /etc/authelia ]; then
    mkdir -p "$TEMP_DIR/etc/authelia"
    cp -r /etc/authelia/* "$TEMP_DIR/etc/authelia/" 2>/dev/null
    log_success "Authelia config"
fi
if [ -d /var/lib/authelia ]; then
    mkdir -p "$TEMP_DIR/var/lib/authelia"
    cp -r /var/lib/authelia/* "$TEMP_DIR/var/lib/authelia/" 2>/dev/null
    log_success "Authelia database"
fi

# 3. Docker configs
log "🐳 Backup Docker..."
if [ -d /etc/docker ]; then
    cp -r /etc/docker "$TEMP_DIR/etc/" 2>/dev/null && log_success "Docker config"
fi

# Docker compose files
if [ -d /opt/docker ]; then
    mkdir -p "$TEMP_DIR/opt/docker"
    cp -r /opt/docker "$TEMP_DIR/opt/" 2>/dev/null && log_success "Docker compose files"
fi

# 4. Nextcloud (config uniquement, pas les données)
log "☁️ Backup Nextcloud config..."
if [ -d /var/www/nextcloud/config ]; then
    mkdir -p "$TEMP_DIR/var/www/nextcloud"
    cp -r /var/www/nextcloud/config "$TEMP_DIR/var/www/nextcloud/" 2>/dev/null
    log_success "Nextcloud config"
fi

# 5. PostgreSQL dump
log "🐘 Backup PostgreSQL..."
if command -v pg_dump &> /dev/null; then
    mkdir -p "$TEMP_DIR/var/lib/postgresql"
    sudo -u postgres pg_dump nextcloud > "$TEMP_DIR/var/lib/postgresql/nextcloud.sql" 2>/dev/null
    log_success "PostgreSQL Nextcloud"
fi

# 6. Pi-hole
log "🛡️ Backup Pi-hole..."
if [ -d /etc/pihole ]; then
    mkdir -p "$TEMP_DIR/etc/pihole"
    cp /etc/pihole/*.toml "$TEMP_DIR/etc/pihole/" 2>/dev/null
    cp /etc/pihole/*.conf "$TEMP_DIR/etc/pihole/" 2>/dev/null
    cp /etc/pihole/*.list "$TEMP_DIR/etc/pihole/" 2>/dev/null
    [ -f /etc/pihole/gravity.db ] && cp /etc/pihole/gravity.db "$TEMP_DIR/etc/pihole/" 2>/dev/null
    [ -f /etc/pihole/pihole-FTL.db ] && cp /etc/pihole/pihole-FTL.db "$TEMP_DIR/etc/pihole/" 2>/dev/null
    log_success "Pi-hole"
fi

# 7. Vaultwarden
log "🔐 Backup Vaultwarden..."
if [ -d /opt/vaultwarden/data ]; then
    mkdir -p "$TEMP_DIR/opt/vaultwarden"
    rsync -a /opt/vaultwarden/data/ "$TEMP_DIR/opt/vaultwarden/data/" 2>/dev/null && log_success "Vaultwarden"
fi

# 8. Uptime Kuma
log "📊 Backup Uptime Kuma..."
if [ -d /opt/uptime-kuma/data ]; then
    mkdir -p "$TEMP_DIR/opt/uptime-kuma"
    rsync -a /opt/uptime-kuma/data/ "$TEMP_DIR/opt/uptime-kuma/data/" 2>/dev/null && log_success "Uptime Kuma"
fi

# 9. Linkding
log "🔖 Backup Linkding..."
if [ -d /opt/linkding/data ]; then
    mkdir -p "$TEMP_DIR/opt/linkding"
    rsync -a /opt/linkding/data/ "$TEMP_DIR/opt/linkding/data/" 2>/dev/null && log_success "Linkding"
fi

# 10. FreshRSS
log "📰 Backup FreshRSS..."
if [ -d /var/www/freshrss/data ]; then
    mkdir -p "$TEMP_DIR/var/www/freshrss"
    rsync -a /var/www/freshrss/data/ "$TEMP_DIR/var/www/freshrss/data/" 2>/dev/null && log_success "FreshRSS"
fi

# 11. Budget app
log "💰 Backup Budget..."
if [ -d /var/www/budget ]; then
    mkdir -p "$TEMP_DIR/var/www/budget"
    rsync -a /var/www/budget/ "$TEMP_DIR/var/www/budget/" 2>/dev/null && log_success "Budget"
fi

# 12. Workout app
log "💪 Backup Workout..."
if [ -d /var/www/workout ]; then
    mkdir -p "$TEMP_DIR/var/www/workout"
    rsync -a /var/www/workout/ "$TEMP_DIR/var/www/workout/" 2>/dev/null && log_success "Workout"
fi

# 13. Fail2ban stats
log "📊 Backup Fail2ban stats..."
if [ -d /var/www/fail2ban-stats ]; then
    mkdir -p "$TEMP_DIR/var/www/fail2ban-stats"
    rsync -a /var/www/fail2ban-stats/ "$TEMP_DIR/var/www/fail2ban-stats/" 2>/dev/null && log_success "Fail2ban stats"
fi

# 14. Vault portal
log "🏠 Backup Vault portal..."
if [ -d /var/www/vault ]; then
    mkdir -p "$TEMP_DIR/var/www/vault"
    rsync -a /var/www/vault/ "$TEMP_DIR/var/www/vault/" 2>/dev/null && log_success "Vault portal"
fi

# 15. Scripts custom
log "📜 Backup scripts custom..."
mkdir -p "$TEMP_DIR/usr/local/bin"
if [ -d /usr/local/bin ]; then
    for script in /usr/local/bin/*.sh; do
        [ -f "$script" ] && cp "$script" "$TEMP_DIR/usr/local/bin/" 2>/dev/null
    done
    log_success "Scripts /usr/local/bin"
fi

# 16. Services systemd custom
log "🔧 Backup services systemd..."
mkdir -p "$TEMP_DIR/etc/systemd/system"
for service in authelia ttyd filebrowser pihole-FTL; do
    if [ -f "/etc/systemd/system/${service}.service" ]; then
        cp "/etc/systemd/system/${service}.service" "$TEMP_DIR/etc/systemd/system/" 2>/dev/null
    fi
done
log_success "Services systemd"

# 17. Fichiers user frederic
log "🏠 Backup dotfiles frederic..."
mkdir -p "$TEMP_DIR/home/frederic"
if [ -d /home/frederic ]; then
    # Copier les dotfiles importants
    for dotfile in .zshrc .zprofile .p10k.zsh .gitconfig .ssh/config; do
        if [ -e "/home/frederic/$dotfile" ]; then
            mkdir -p "$TEMP_DIR/home/frederic/$(dirname $dotfile)"
            cp -r "/home/frederic/$dotfile" "$TEMP_DIR/home/frederic/$dotfile" 2>/dev/null
        fi
    done
    log_success "Dotfiles frederic"
fi

# 18. Crontabs
log "⏰ Backup crontabs..."
mkdir -p "$TEMP_DIR/crontabs"
crontab -u frederic -l > "$TEMP_DIR/crontabs/crontab-frederic.txt" 2>/dev/null && log_success "Crontab frederic"
crontab -l > "$TEMP_DIR/crontabs/crontab-root.txt" 2>/dev/null && log_success "Crontab root"

# 19. Liste des paquets
log "📦 Export liste des paquets..."
dpkg --get-selections > "$TEMP_DIR/packages.list"
apt-mark showmanual > "$TEMP_DIR/packages-manual.list"
log_success "Liste des paquets"

# 20. Docker containers running
log "🐳 Export Docker containers..."
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > "$TEMP_DIR/docker-containers.txt" 2>/dev/null
log_success "Docker containers"

# 21. Services actifs
log "🔧 Export services actifs..."
systemctl list-unit-files --state=enabled > "$TEMP_DIR/services-enabled.list"
log_success "Services actifs"

# 22. Informations système
log "💾 Export infos système..."
{
    echo "=== Système ==="
    uname -a
    hostname
    echo ""
    echo "=== Disques ==="
    df -h
    echo ""
    echo "=== RAM ==="
    free -h
    echo ""
    echo "=== IP ==="
    ip addr | grep -E "inet |inet6 "
} > "$TEMP_DIR/system-info.txt"
log_success "Infos système"

# 23. Compression
log "📦 Compression du backup..."
cd "$LOCAL_BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}/"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    log_success "Backup créé : ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
else
    log_error "Erreur lors de la compression"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Nettoyage répertoire temporaire
rm -rf "$TEMP_DIR"

# 24. Envoi vers VPS
log "🚀 Envoi vers VPS OVH..."

# Créer le répertoire sur le VPS si nécessaire
ssh "$VPS_HOST" "mkdir -p $VPS_BACKUP_DIR" 2>/dev/null

# Envoyer le backup
rsync -avz --progress "${LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "${VPS_HOST}:${VPS_BACKUP_DIR}/"

if [ $? -eq 0 ]; then
    log_success "Backup envoyé vers VPS"
    
    # Supprimer le backup local après envoi réussi
    rm -f "${LOCAL_BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    log_success "Backup local supprimé"
else
    log_error "Erreur envoi VPS - backup conservé localement"
fi

# 25. Rotation sur le VPS (garder 30 derniers)
log "🧹 Rotation des backups sur VPS..."
ssh "$VPS_HOST" "cd $VPS_BACKUP_DIR && ls -t backup_trigkey_*.tar.gz 2>/dev/null | tail -n +31 | xargs -r rm -f"
REMOTE_COUNT=$(ssh "$VPS_HOST" "ls -1 $VPS_BACKUP_DIR/backup_trigkey_*.tar.gz 2>/dev/null | wc -l")
log_success "Backups sur VPS : ${REMOTE_COUNT}"

log "=========================================="
log "=== ✅ Backup terminé avec succès ! ==="
log "=========================================="
log "📊 Fichier: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
log "☁️ VPS: ${VPS_HOST}:${VPS_BACKUP_DIR}"
echo "" >> "$LOG_FILE"
