#!/bin/bash

# Backup complet VM Debian - leblais.net
# Inclut tous les services et configurations

# Configuration
BACKUP_DIR="/mnt/WD_Freebox/backups/vm-debian"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_vm_${DATE}"
TEMP_DIR="/tmp/${BACKUP_NAME}"
LOG_FILE="/var/log/backup-vm.log"
RETENTION_DAYS=30  # Garder 30 jours de backups

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
mkdir -p "$BACKUP_DIR"
mkdir -p "$TEMP_DIR"

log "=========================================="
log "=== Début du backup VM leblais.net ==="
log "=========================================="

# 1. Configurations système de base
log "📦 Backup configurations système de base..."
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

# UFW
if [ -d /etc/ufw ]; then
    cp -r /etc/ufw "$TEMP_DIR/etc/" 2>/dev/null && log_success "UFW"
fi

# SSH
if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config "$TEMP_DIR/etc/" 2>/dev/null && log_success "SSH config"
fi

# fstab
if [ -f /etc/fstab ]; then
    cp /etc/fstab "$TEMP_DIR/etc/" 2>/dev/null && log_success "fstab"
fi

# 2. Authelia (CRITIQUE)
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

# 3. Cockpit
log "⚙️ Backup Cockpit..."
if [ -d /etc/cockpit ]; then
    cp -r /etc/cockpit "$TEMP_DIR/etc/" 2>/dev/null && log_success "Cockpit"
fi

# 4. Docker
log "🐳 Backup Docker..."
if [ -d /etc/docker ]; then
    cp -r /etc/docker "$TEMP_DIR/etc/" 2>/dev/null && log_success "Docker config"
fi

# XX. Actual Budget
log "💰 Backup Actual Budget..."
if [ -d /opt/actual-budget ]; then
    mkdir -p "$TEMP_DIR/opt/actual-budget"
    
    # Docker compose
    cp /opt/actual-budget/docker-compose.yml "$TEMP_DIR/opt/actual-budget/" 2>/dev/null
    
    # Data (base SQLite)
    if [ -d /opt/actual-budget/data ]; then
        cp -r /opt/actual-budget/data "$TEMP_DIR/opt/actual-budget/" 2>/dev/null
    fi
    
    log_success "Actual Budget"
else
    log_warning "Actual Budget non installé, skip"
fi

# 5. OpenVPN / ProtonVPN
log "🌐 Backup ProtonVPN..."
if [ -d /etc/openvpn ]; then
    mkdir -p "$TEMP_DIR/etc/openvpn"
    cp -r /etc/openvpn/protonvpn "$TEMP_DIR/etc/openvpn/" 2>/dev/null && log_success "ProtonVPN config"
fi

# 6. Services systemd custom
log "🔧 Backup services systemd custom..."
mkdir -p "$TEMP_DIR/etc/systemd/system"
for service in authelia.service ttyd.service rtorrent.service protonvpn-namespace.service setup-vpn-namespace.service; do
    if [ -f "/etc/systemd/system/$service" ]; then
        cp "/etc/systemd/system/$service" "$TEMP_DIR/etc/systemd/system/" 2>/dev/null && log_success "$service"
    fi
done

# 7. Scripts custom
log "📜 Backup scripts custom..."
mkdir -p "$TEMP_DIR/usr/local/bin"
if [ -d /usr/local/bin ]; then
    # Copier tous les scripts custom (sauf docker-compose qui est gros)
    for script in /usr/local/bin/*; do
        if [ -f "$script" ] && [ "$(basename $script)" != "docker-compose" ]; then
            cp "$script" "$TEMP_DIR/usr/local/bin/" 2>/dev/null
        fi
    done
    log_success "Scripts /usr/local/bin"
fi

# 8. Credentials sécurisés
log "🔑 Backup credentials..."
mkdir -p "$TEMP_DIR/root"
[ -f /root/.smbcredentials ] && cp /root/.smbcredentials "$TEMP_DIR/root/" 2>/dev/null && log_success "SMB credentials"

# rclone config (pour restauration)
if [ -f /home/freebox/.config/rclone/rclone.conf ]; then
    mkdir -p "$TEMP_DIR/home/freebox/.config/rclone"
    cp /home/freebox/.config/rclone/rclone.conf "$TEMP_DIR/home/freebox/.config/rclone/" 2>/dev/null && log_success "rclone config"
fi

# rclone config root (utilisée par le script backup)
if [ -f /root/.config/rclone/rclone.conf ]; then
    mkdir -p "$TEMP_DIR/root/.config/rclone"
    cp /root/.config/rclone/rclone.conf "$TEMP_DIR/root/.config/rclone/" 2>/dev/null && log_success "rclone config (root)"
fi

# Variables d'environnement Caddy (OVH API)
if [ -f /etc/caddy/caddy.env ]; then
    cp /etc/caddy/caddy.env "$TEMP_DIR/etc/caddy/" 2>/dev/null && log_success "Caddy env (OVH API)"
fi

# 9. rtorrent config
log "🌊 Backup rtorrent..."
mkdir -p "$TEMP_DIR/home/freebox/rtorrent"
if [ -f /root/.rtorrent.rc ]; then
    cp /root/.rtorrent.rc "$TEMP_DIR/root/" 2>/dev/null && log_success "rtorrent config (root)"
fi

if [ -d /home/freebox/rtorrent ]; then
    rsync -a /home/freebox/rtorrent/ "$TEMP_DIR/home/freebox/rtorrent/" 2>/dev/null && log_success "rtorrent session"
fi

# 10. ruTorrent config
log "📡 Backup ruTorrent..."
if [ -d /var/www/ruTorrent/conf ]; then
    mkdir -p "$TEMP_DIR/var/www/ruTorrent"
    cp -r /var/www/ruTorrent/conf "$TEMP_DIR/var/www/ruTorrent/" 2>/dev/null && log_success "ruTorrent config"
fi

# 11. Sites web
log "🌐 Backup sites web..."
mkdir -p "$TEMP_DIR/var/www"
if [ -d /var/www ]; then
    # Exclure ruTorrent complet (déjà fait la config)
    rsync -a --exclude='ruTorrent' /var/www/ "$TEMP_DIR/var/www/" 2>/dev/null && log_success "Sites web"
fi

# XX. Pi-hole
log "🛡️ Backup Pi-hole..."
if [ -d /etc/pihole ]; then
    mkdir -p "$TEMP_DIR/etc/pihole"
    
    # Config files
    cp /etc/pihole/*.toml "$TEMP_DIR/etc/pihole/" 2>/dev/null
    cp /etc/pihole/*.conf "$TEMP_DIR/etc/pihole/" 2>/dev/null
    cp /etc/pihole/*.list "$TEMP_DIR/etc/pihole/" 2>/dev/null
    
    # Database
    if [ -f /etc/pihole/gravity.db ]; then
        cp /etc/pihole/gravity.db "$TEMP_DIR/etc/pihole/" 2>/dev/null
    fi
    
    if [ -f /etc/pihole/pihole-FTL.db ]; then
        cp /etc/pihole/pihole-FTL.db "$TEMP_DIR/etc/pihole/" 2>/dev/null
    fi
    
    log_success "Pi-hole"
else
    log_warning "Pi-hole non installé, skip"
fi

# 14. Vaultwarden (si installé)
log "🔐 Backup Vaultwarden..."
if [ -d /opt/vaultwarden/data ]; then
    mkdir -p "$TEMP_DIR/opt/vaultwarden"
    rsync -a /opt/vaultwarden/data/ "$TEMP_DIR/opt/vaultwarden/data/" 2>/dev/null && log_success "Vaultwarden"
else
    log_warning "Vaultwarden non installé, skip"
fi

# XX. Uptime Kuma (si installé)
log "📊 Backup Uptime Kuma..."
if [ -d /opt/uptime-kuma/data ]; then
    mkdir -p "$TEMP_DIR/opt/uptime-kuma"
    rsync -a /opt/uptime-kuma/data/ "$TEMP_DIR/opt/uptime-kuma/data/" 2>/dev/null && log_success "Uptime Kuma"
else
    log_warning "Uptime Kuma non installé, skip"
fi

# XX. Linkding (si installé)
log "🔖 Backup Linkding..."
if [ -d /opt/linkding/data ]; then
    mkdir -p "$TEMP_DIR/opt/linkding"
    rsync -a /opt/linkding/data/ "$TEMP_DIR/opt/linkding/data/" 2>/dev/null && log_success "Linkding"
else
    log_warning "Linkding non installé, skip"
fi

# 15. Crontabs
log "⏰ Backup crontabs..."
mkdir -p "$TEMP_DIR/crontabs"

# Crontab user freebox
if crontab -u freebox -l &>/dev/null; then
    crontab -u freebox -l > "$TEMP_DIR/crontabs/crontab-freebox.txt" 2>/dev/null && log_success "Crontab freebox"
fi

# Crontab root
if crontab -l &>/dev/null; then
    crontab -l > "$TEMP_DIR/crontabs/crontab-root.txt" 2>/dev/null && log_success "Crontab root"
fi

# 16. Liste des paquets installés
log "📦 Export liste des paquets..."
dpkg --get-selections > "$TEMP_DIR/packages.list"
apt-mark showmanual > "$TEMP_DIR/packages-manual.list"
log_success "Liste des paquets"

# 17. Règles UFW
log "🔥 Export règles UFW..."
ufw status numbered > "$TEMP_DIR/ufw-rules.txt" 2>/dev/null
log_success "Règles UFW"

# 18. Services actifs
log "🔧 Export liste des services..."
systemctl list-unit-files --state=enabled > "$TEMP_DIR/services-enabled.list"
log_success "Services actifs"

# 19. Informations système
log "💾 Export informations système..."
{
    echo "=== Système ==="
    uname -a
    echo ""
    echo "=== Disques ==="
    df -h
    echo ""
    echo "=== RAM ==="
    free -h
    echo ""
    echo "=== IP ==="
    ip addr
} > "$TEMP_DIR/system-info.txt"
log_success "Informations système"

# 20. Compression du backup
log "📦 Compression du backup..."
cd /tmp
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}/"

# Vérification
if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
    log_success "Backup créé : ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
else
    log_error "Erreur lors de la création du backup"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 21. Nettoyage du répertoire temporaire
rm -rf "$TEMP_DIR"

# 22. Rotation des backups locaux (conservation : 30 derniers)
log "🧹 Rotation des backups locaux (conservation : 30 derniers)..."
BACKUP_LIST=$(ls -t "$BACKUP_DIR"/backup_vm_*.tar.gz 2>/dev/null)
BACKUP_COUNT=$(echo "$BACKUP_LIST" | wc -l)

if [ $BACKUP_COUNT -gt 30 ]; then
    echo "$BACKUP_LIST" | tail -n +31 | while read old_backup; do
        log "Suppression ancien backup : $(basename $old_backup)"
        rm -f "$old_backup"
    done
fi

# Comptage des backups restants
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/backup_vm_*.tar.gz 2>/dev/null | wc -l)
log "📊 Backups locaux conservés : ${BACKUP_COUNT}"

# 23. Upload vers Google Drive
if command -v rclone &> /dev/null; then
    log "☁️  Upload vers Google Drive..."
    
    # Crée le dossier si nécessaire
    
    # Upload du backup
    rclone copy "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" gdrive-crypt: -P
    
    if [ $? -eq 0 ]; then
        log_success "Upload Google Drive réussi"
        
        # Suppression des anciens backups sur Drive (garde 30 derniers)
        log "🧹 Rotation Google Drive (conservation : 30 derniers)..."
        
        # Lister tous les backups sur Drive
        GDRIVE_BACKUPS=$(rclone lsf gdrive-crypt: | grep "backup_vm_" | sort -r)
        GDRIVE_COUNT=$(echo "$GDRIVE_BACKUPS" | wc -l)
        
        if [ $GDRIVE_COUNT -gt 30 ]; then
            echo "$GDRIVE_BACKUPS" | tail -n +31 | while read old_backup; do
                rclone delete "gdrive-crypt:${old_backup}"
                log "Suppression GDrive : $old_backup"
            done
        fi
        
        log_success "Rotation Google Drive terminée"
    else
        log_error "Erreur upload Google Drive"
    fi
else
    log_warning "rclone non installé, skip Google Drive"
fi

log "=========================================="
log "=== ✅ Backup terminé avec succès ! ==="
log "=========================================="
log "📊 Fichier: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
log "💾 Local: ${BACKUP_DIR}"
log "☁️  GDrive: gdrive-crypt: (chiffré E2EE)"
echo "" >> "$LOG_FILE"
