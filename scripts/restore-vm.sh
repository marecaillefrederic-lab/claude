#!/bin/bash

# Vérification argument
if [ -z "$1" ]; then
    echo "Usage: $0 <fichier_backup.tar.gz>"
    echo "Backups disponibles :"
    ls -lh /mnt/WD_Freebox/backups/vm-debian/
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="/tmp/restore_$(date +%Y%m%d_%H%M%S)"

echo "=== RESTAURATION COMPLÈTE DE LA VM ==="
echo "Backup source : $BACKUP_FILE"
echo ""
read -p "⚠️  Cela va ÉCRASER toutes les configurations actuelles. Continuer ? (oui/non) : " confirm

if [ "$confirm" != "oui" ]; then
    echo "Restauration annulée."
    exit 0
fi

# Extraction
echo "[1/6] Extraction du backup..."
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1

if [ $? -ne 0 ]; then
    echo "✗ Erreur lors de l'extraction"
    exit 1
fi

# Arrêt des services
echo "[2/6] Arrêt des services..."
systemctl stop caddy
systemctl stop fail2ban
systemctl stop wg-quick@wg0
systemctl stop AdGuardHome

# Restauration des configurations
echo "[3/6] Restauration /etc..."
cp -r "$RESTORE_DIR/etc/caddy"/* /etc/caddy/ 2>/dev/null
cp -r "$RESTORE_DIR/etc/fail2ban"/* /etc/fail2ban/ 2>/dev/null
cp -r "$RESTORE_DIR/etc/wireguard"/* /etc/wireguard/ 2>/dev/null
cp -r "$RESTORE_DIR/etc/ufw"/* /etc/ufw/ 2>/dev/null
cp "$RESTORE_DIR/etc/fstab" /etc/fstab 2>/dev/null
cp "$RESTORE_DIR/etc/sshd_config" /etc/ssh/sshd_config 2>/dev/null

echo "[4/6] Restauration credentials..."
cp "$RESTORE_DIR/root/.smbcredentials" /root/.smbcredentials 2>/dev/null
chmod 600 /root/.smbcredentials

echo "[5/6] Restauration sites web et services..."
rsync -a --delete "$RESTORE_DIR/var/www/" /var/www/ 2>/dev/null
rsync -a --delete "$RESTORE_DIR/opt/AdGuardHome/" /opt/AdGuardHome/ 2>/dev/null

# Permissions
chown -R caddy:caddy /var/www
chmod -R 755 /var/www

# Redémarrage des services
echo "[6/6] Redémarrage des services..."
systemctl daemon-reload
systemctl restart caddy
systemctl restart fail2ban
systemctl restart wg-quick@wg0
systemctl restart AdGuardHome
systemctl restart ssh

# Nettoyage
rm -rf "$RESTORE_DIR"

echo ""
echo "✓ Restauration terminée avec succès !"
echo "⚠️  Vérifie que tous les services fonctionnent :"
echo "   systemctl status caddy"
echo "   systemctl status fail2ban"
echo "   systemctl status wg-quick@wg0"
echo "   systemctl status AdGuardHome"
