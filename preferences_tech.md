# Infrastructure Technique - leblais.net

**Dernière mise à jour : 16 novembre 2025**

---

## 🎯 Vue d'ensemble

Infrastructure auto-hébergée complète sur VM Debian 12 ARM64 (Freebox Server Ultra).

**Caractéristiques système :**
- **RAM** : 2 GB (optimisée)
- **Stockage VM** : 32 GB
- **Stockage externe** : 1 TB SMB (Freebox)
- **Utilisateurs** : 3 (famille)
- **Services** : 15+ services auto-hébergés
- **Sécurité** : A+ (SSL, Fail2ban, Authelia)
- **Uptime** : 99.9% (monitoring 24/7)

---

## 📊 Nextcloud - Cloud Familial Souverain

**URL** : https://cloud.leblais.net  
**Version** : Nextcloud 30+ (dernière stable)  
**Installation** : `/var/www/nextcloud`  
**Données** : `/mnt/WD_Freebox/nextcloud-data/`  
**Base de données** : PostgreSQL 15  
**Cache** : Redis  
**Sécurité** : A+ (SSL Labs)  
**RAM optimisée** : 500-800 MB disponibles sur 2 GB

### Architecture

```
Caddy (Reverse Proxy + SSL)
    ↓
PHP-FPM 8.2 (5 workers max)
    ↓
Nextcloud (290 GB, 31k+ fichiers)
    ↓
PostgreSQL 15 (64 MB shared_buffers)
Redis (64 MB cache)
SMB Mount (Freebox 1 TB)
```

### Configuration optimisée pour 2 GB RAM

**PHP-FPM** : `/etc/php/8.2/fpm/pool.d/www.conf`
```ini
pm = dynamic
pm.max_children = 5
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 2
pm.max_requests = 500
```

**PostgreSQL** : `/etc/postgresql/15/main/postgresql.conf`
```ini
shared_buffers = 64MB
effective_cache_size = 256MB
work_mem = 2MB
maintenance_work_mem = 16MB
max_connections = 15
```

**Redis** : `/etc/redis/redis.conf`
```ini
maxmemory 64mb
maxmemory-policy allkeys-lru
```

**Nextcloud** : `config/config.php`
```php
'memcache.local' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'redis' => [
    'host' => 'localhost',
    'port' => 6379,
],
'enable_previews' => false,  // Économie RAM
'preview_max_x' => 2048,
'preview_max_y' => 2048,
```

### Migration Google Drive réussie

**Données migrées** :
- Volume : 290 GB
- Fichiers : 41,665 fichiers initiaux
- Doublons supprimés : ~50 GB
- Fichiers finaux : ~31,700 fichiers
- Temps total : ~15 heures (scan + migration + optimisation)

**Méthode utilisée** : rclone copy → SMB → Scan Nextcloud progressif

**Script de nettoyage intelligent** : `/usr/local/bin/move-duplicates-smart.sh`
- Analyse intelligente des doublons
- Règles spécifiques par dossier
- Détection par hash SHA256
- Préservation des originaux

### Utilisateurs et quotas

| Utilisateur | Rôle | Quota | Stockage utilisé | Fichiers |
|-------------|------|-------|------------------|----------|
| frederic | Admin | Illimité | ~50 GB | ~10k |
| sylvie | User | Illimité | ~240 GB | ~21k |
| (jerome) | User | (À créer) | - | - |

### Apps actives (optimisées)

**Essentielles** :
- ✅ `files` - Gestion fichiers
- ✅ `dav` - CalDAV/CardDAV
- ✅ `calendar` - Calendrier
- ✅ `contacts` - Contacts (synchronisation DAVx5 mobile)
- ✅ `notes` - Prise de notes
- ✅ `mail` - Client email
- ✅ `talk` - Chat/Visio (Spreed)
- ✅ `files_sharing` - Partage fichiers
- ✅ `files_trashbin` - Corbeille
- ✅ `files_versions` - Versions (désactivé temporairement pour RAM)

**Visualisation** :
- ✅ `viewer` - Prévisualisation images/vidéos
- ✅ `files_pdfviewer` - Prévisualisation PDF
- ✅ `text` - Éditeur texte/markdown

**Désactivées (économie RAM)** :
- ❌ `photos` - App Photos (previews désactivés)
- ❌ `activity` - Flux d'activité
- ❌ `dashboard` - Tableau de bord
- ❌ `recommendations` - Recommandations
- ❌ `weather_status` - Météo

### Scripts de maintenance

**Cleanup automatique des verrous** : `/usr/local/bin/nextcloud-cleanup-locks.sh`
```bash
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
        curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=up&msg=Cleanup_${LOCKS_DELETED}_locks"
    fi
fi
```
**Exécution** : Cron toutes les heures  
**Log** : `/var/log/nextcloud-cleanup.log`

**Maintenance mensuelle** : `/usr/local/bin/nextcloud-maintenance.sh`
```bash
#!/bin/bash
# Maintenance complète Nextcloud

echo "Nextcloud Maintenance - $(date)"

# Mode maintenance ON
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Nettoyer fichiers orphelins
echo "Nettoyage fichiers orphelins..."
sudo -u www-data php /var/www/nextcloud/occ files:cleanup

# Optimiser PostgreSQL
echo "Optimisation PostgreSQL..."
sudo -u postgres psql -d nextcloud -c "VACUUM ANALYZE;"

# Scanner fichiers
echo "Scan fichiers..."
sudo -u www-data php /var/www/nextcloud/occ files:scan --all

# Mode maintenance OFF
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# Log RAM et espace
echo "RAM: $(free -h | grep Mem)"
echo "Espace: $(df -h /mnt/WD_Freebox | grep -v Filesystem)"

# Push vers Uptime Kuma
curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=up&msg=Maintenance_OK"

echo "Maintenance terminée !"
```
**Exécution** : Cron tous les 20 jours à 2h du matin

**Check updates** : `/usr/local/bin/nextcloud-check-update.sh`
```bash
#!/bin/bash
# Vérifier mises à jour Nextcloud disponibles

UPDATE_AVAILABLE=$(sudo -u www-data php /var/www/nextcloud/occ update:check | grep -c "Update available")

if [ "$UPDATE_AVAILABLE" -gt 0 ]; then
    curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=up&msg=Update_Available"
else
    curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=up&msg=Up_to_date"
fi
```
**Exécution** : Cron tous les lundis à 9h

**Health check amélioré** : `/usr/local/bin/nextcloud-health-check.sh`
```bash
#!/bin/bash
# Health check Nextcloud + RAM + Détection cron bloqué

# Vérifier status Nextcloud
STATUS=$(curl -s https://cloud.leblais.net/status.php | grep -c "installed")

# RAM disponible
RAM_AVAIL=$(free -m | grep Mem | awk '{print $7}')

# Vérifier si un cron tourne depuis trop longtemps (>15 min)
CRON_BLOCKED=0
CRON_RUNNING=$(ps -eo pid,etime,cmd | grep "nextcloud/cron.php" | grep -v grep)

if [ ! -z "$CRON_RUNNING" ]; then
    # Extraire le temps d'exécution (format MM:SS ou HH:MM:SS)
    ETIME=$(echo "$CRON_RUNNING" | awk '{print $2}')
    
    # Convertir en secondes (simplification : si contient ":", c'est au moins 1 min)
    if [[ "$ETIME" == *:*:* ]]; then
        # Format HH:MM:SS - c'est bloqué !
        CRON_BLOCKED=1
        PID=$(echo "$CRON_RUNNING" | awk '{print $1}')
        echo "$(date) - CRON BLOQUÉ détecté ! PID: $PID, Durée: $ETIME" >> /var/log/nextcloud-cleanup.log
    fi
fi

if [ "$STATUS" -eq 1 ] && [ "$RAM_AVAIL" -gt 200 ] && [ "$CRON_BLOCKED" -eq 0 ]; then
    curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=up&msg=OK_RAM_${RAM_AVAIL}MB"
else
    if [ "$CRON_BLOCKED" -eq 1 ]; then
        curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=down&msg=CRON_BLOCKED"
    else
        curl -s "https://uptime.leblais.net/api/push/PUSH_URL?status=down&msg=ERROR_RAM_${RAM_AVAIL}MB"
    fi
fi
```
**Exécution** : Cron toutes les 6 heures

**Scan doublons** : `/usr/local/bin/move-duplicates-smart.sh`
```bash
#!/bin/bash
# Détection intelligente doublons Nextcloud

# Règles spécifiques par dossier
# - sauv_pc_jerome : analyse interne uniquement
# - Sylvie ↔ Samsung : comparaison croisée
# - Déplacement vers DOUBLONS_A_VERIFIER
```
**Exécution** : Manuel (après migration importante)

### Background Jobs (CRITIQUE)

**Cron configuré avec timeout de 10 minutes** : 
```bash
*/5 * * * * timeout 600 sudo -u www-data php -f /var/www/nextcloud/cron.php
```

**⚠️ Important** : 
- Utiliser `cron.php` et PAS `occ background:cron` (incompatible)
- Timeout de 600s (10 min) empêche les blocages prolongés
- Cleanup automatique des verrous toutes les heures

**Vérification** :
- Nextcloud web → Paramètres → Administration → Paramètres de base
- "Dernière tâche exécutée" doit être < 5 minutes
- Mode : "Cron (Recommandé)" ✅

**Historique problèmes résolus** :
- ✅ 18,553 jobs anciens supprimés (accumulation initiale)
- ✅ 902 verrous de fichiers nettoyés (16 nov 2025)
- ✅ Timeout ajouté pour éviter blocages >10 min
- ✅ Script cleanup automatique mis en place
- Solution verrous : `DELETE FROM oc_file_locks WHERE ttl < EXTRACT(EPOCH FROM NOW())`
- Solution jobs bloqués : `UPDATE oc_jobs SET reserved_at = 0 WHERE reserved_at > 0`

### Synchronisation mobile

**DAVx5** (Android) :
- URL : https://cloud.leblais.net/remote.php/dav
- Contacts : Synchronisé ✅
- Calendrier : Synchronisé ✅
- Upload auto photos : Configuré (WiFi uniquement)

**App Nextcloud mobile** :
- Auto-upload Camera → `/InstantUpload`
- Miniatures générées localement (pas de charge serveur)
- Synchronisation continue

### Monitoring Uptime Kuma

**Monitors Nextcloud** :

| Monitor | Type | Intervalle | URL/Script |
|---------|------|------------|------------|
| Nextcloud Web | HTTPS | 60s | https://cloud.leblais.net/status.php |
| Nextcloud Update Check | Push | 7 jours | /usr/local/bin/nextcloud-check-update.sh |
| Nextcloud Maintenance | Push | 20 jours | /usr/local/bin/nextcloud-maintenance.sh |
| Nextcloud Health Check | Push | 6h | /usr/local/bin/nextcloud-health-check.sh |

**Statut actuel** : 100% uptime ✅

### Performances et statistiques

**RAM** :
- Base (idle) : ~680 MB utilisés / 2 GB
- Navigation web : +50-100 MB
- Upload fichier : +20-50 MB
- Scan fichiers : +150-250 MB (temporaire)
- Disponible moyenne : 500-800 MB ✅

**Espace disque** :
- Total Freebox SMB : 1 TB
- Nextcloud : ~240 GB utilisés (après nettoyage doublons)
- Backups locaux : ~66-107 MB (compressés)
- Disponible : ~760 GB

**Performances** :
- Chargement liste 300 fichiers : < 2s
- Upload 100 MB : ~10-15s (selon réseau)
- Scan 10k fichiers : ~5-10 min
- Preview image à la demande : < 1s

### Caddy configuration

**Nextcloud reverse proxy** : `/etc/caddy/Caddyfile`
```
cloud.leblais.net {
    log {
        output file /var/log/caddy/nextcloud-access.log
    }

    header {
        Strict-Transport-Security "max-age=31536000;"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "no-referrer"
        X-XSS-Protection "1; mode=block"
        X-Permitted-Cross-Domain-Policies "none"
        X-Robots-Tag "noindex, nofollow"
    }

    reverse_proxy 127.0.0.1:8080

    redir /.well-known/carddav /remote.php/dav 301
    redir /.well-known/caldav /remote.php/dav 301
}
```

### Commandes utiles

**Scan fichiers** :
```bash
# Scanner un utilisateur
sudo -u www-data php /var/www/nextcloud/occ files:scan USERNAME -v

# Scanner un dossier spécifique
sudo -u www-data php /var/www/nextcloud/occ files:scan --path="/username/files/FOLDER" -v

# Nettoyer fichiers orphelins
sudo -u www-data php /var/www/nextcloud/occ files:cleanup
```

**Maintenance** :
```bash
# Mode maintenance ON
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Mode maintenance OFF
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# Optimiser base de données
sudo -u postgres psql -d nextcloud -c "VACUUM ANALYZE;"
```

**Debug verrous et jobs** :
```bash
# Débloquer verrous expirés (à faire en cas de problème)
sudo -u postgres psql -d nextcloud -c "DELETE FROM oc_file_locks WHERE ttl < EXTRACT(EPOCH FROM NOW());"

# Débloquer jobs réservés
sudo -u postgres psql -d nextcloud -c "UPDATE oc_jobs SET reserved_at = 0 WHERE reserved_at > 0;"

# Voir logs
tail -100 /mnt/WD_Freebox/nextcloud-data/nextcloud.log

# Voir logs cleanup automatique
tail -50 /var/log/nextcloud-cleanup.log
```

**Apps** :
```bash
# Lister apps
sudo -u www-data php /var/www/nextcloud/occ app:list

# Désactiver app
sudo -u www-data php /var/www/nextcloud/occ app:disable APP_NAME

# Activer app
sudo -u www-data php /var/www/nextcloud/occ app:enable APP_NAME
```

**Utilisateurs** :
```bash
# Créer utilisateur
sudo -u www-data php /var/www/nextcloud/occ user:add --display-name="Nom Complet" USERNAME

# Réinitialiser mot de passe
sudo -u www-data php /var/www/nextcloud/occ user:resetpassword USERNAME
```

### Sauvegardes

**Nextcloud inclus dans backup-vm.sh** :
- Configuration Nextcloud : `/var/www/nextcloud/config/`
- Base de données PostgreSQL : dump SQL
- Données utilisateurs : `/mnt/WD_Freebox/nextcloud-data/` (SMB)

**Backup quotidien** : 3h du matin  
**Rétention** : 30 jours  
**Destination** : Local + Google Drive chiffré

### Prochaines étapes

- [ ] DD externe 1 TB → Backup local (remplacer Google Drive)
- [ ] Compte utilisateur Jerome
- [ ] Client desktop Nextcloud sur PC famille
- [ ] Partages inter-utilisateurs
- [ ] Évaluer OnlyOffice sur VPS externe (si besoin édition collaborative)

---

## 🐳 Docker Services

### Vaultwarden (Gestionnaire de mots de passe)

**URL** : https://pass.leblais.net  
**Installation** : `/opt/vaultwarden` (Docker)  
**Port interne** : 8000  
**Base de données** : SQLite dans `/opt/vaultwarden/data`  
**Container** : vaultwarden  
**Image** : vaultwarden/server:latest  
**Fail2ban actif** : caddy-vaultwarden  
**Backup** : Base de données SQLite incluse dans backup quotidien

### Uptime Kuma (Monitoring 24/7)

**URL** : https://uptime.leblais.net  
**Installation** : `/opt/uptime-kuma` (Docker)  
**Port interne** : 3001  
**Base de données** : SQLite dans `/opt/uptime-kuma/data`  
**Container** : uptime-kuma  
**Image** : louislam/uptime-kuma:latest  
**Monitors actifs** : 15+ (tous les services)  
**Notifications** : Prêt (Telegram/Email configurables)  
**Fail2ban actif** : caddy-uptime

**Monitors configurés** :
- Pi-hole Update Check (Push)
- VPN ProtonVPN Status (Push)
- Nextcloud Web (HTTPS)
- Nextcloud Update Check (Push)
- Nextcloud Maintenance (Push)
- Nextcloud Health Check (Push)
- Tous les services web (HTTPS)

### Linkding (Gestionnaire de bookmarks)

**URL** : https://bookmarks.leblais.net  
**Installation** : `/opt/linkding` (Docker)  
**Port interne** : 9092  
**Base de données** : SQLite dans `/opt/linkding/data`  
**Container** : linkding  
**Image** : sissbruecker/linkding:latest  
**Compte admin** : freebox  
**Fail2ban actif** : caddy-bookmarks

### Actual Budget (Gestion finances personnelles)

**URL** : https://budget.leblais.net  
**Installation** : `/opt/actual-budget` (Docker)  
**Port interne** : 5006  
**Container** : actual-budget  
**Image** : actualbudget/actual-server:latest  
**Base de données** : SQLite dans `/opt/actual-budget/data`  
**Fail2ban actif** : caddy-budget

---

## 🌐 Infrastructure de base

### Caddy (Reverse Proxy)

**Configuration** : `/etc/caddy/Caddyfile`  
**Logs** : `/var/log/caddy/`  
**Certificats SSL** : Automatiques via DNS challenge OVH  
**Credentials OVH API** : `/etc/caddy/caddy.env`  

**Variables d'environnement** :
- OVH_APPLICATION_KEY
- OVH_APPLICATION_SECRET
- OVH_CONSUMER_KEY

**Domaines actifs** : 15+ sous-domaines leblais.net

### Fail2ban (Protection brute-force)

**Configuration** : `/etc/fail2ban/jail.local`  
**Filtres personnalisés** : `/etc/fail2ban/filter.d/`  

**Jails actives (13 jails)** :
- sshd (port 24589)
- caddy-cockpit
- caddy-freebox
- caddy-freshrss
- caddy-terminal
- caddy-torrent
- caddy-vaultwarden
- caddy-uptime
- caddy-bookmarks
- caddy-pihole
- caddy-budget
- caddy-nextcloud
- fail2ban-stats (META - auto-protection)

**Dashboard Fail2ban** : https://fail2ban.leblais.net

### UFW (Pare-feu)

**Ports autorisés** :
- 22 (SSH - port custom 24589)
- 80, 443 (HTTP/HTTPS)
- 51820/udp (WireGuard VPN)
- 3000 (Cockpit)
- 9090 (Cockpit alt)

**Règles spécifiques** : Interface wg0 (VPN)

### SSH

**Port custom** : 24589 (non-standard)  
**Redirection Freebox** : WAN 24589 → LAN 22  
**Authentification** : Clé SSH uniquement (pas de password)

---

## 🔐 Authentification et Sécurité

### Authelia (SSO)

**URL** : https://auth.leblais.net  
**Installation** : `/opt/authelia`  
**Port interne** : 9091  
**Configuration** : `/etc/authelia/configuration.yml`  
**Base utilisateurs** : `/etc/authelia/users_database.yml`  
**Base de données** : SQLite dans `/var/lib/authelia`  
**Service** : authelia.service  
**Logs** : `journalctl -u authelia -f`

**Services protégés** : Terminal Web, services sensibles via Caddy

---

## 🌍 Services Web

### Pi-hole (Blocage publicités DNS)

**URL** : https://pihole.leblais.net/admin  
**Installation** : Système (pas Docker)  
**Port web** : 8081  
**Base de données** : SQLite (`/etc/pihole/gravity.db`, `pihole-FTL.db`)  
**Service** : pihole-FTL.service  
**Serveur web** : CivetWeb (intégré)  
**Logs** : `/var/log/pihole/`  
**Configuration** : `/etc/pihole/pihole.toml`  
**Fail2ban actif** : caddy-pihole

**Commandes utiles** :
```bash
pihole status
pihole -g              # Update gravity
pihole setpassword
pihole restartdns
```

**Script update check** : `/usr/local/bin/check-pihole-update.sh`  
**Push Uptime Kuma** : Tous les dimanches 6h

### Terminal Web (ttyd)

**URL** : https://terminal.leblais.net  
**Installation** : `/usr/local/bin/ttyd`  
**Port interne** : 7681  
**Service** : ttyd.service  
**Authentification** : Via Authelia  
**Commande** : bash en lecture seule  
**Logs** : `journalctl -u ttyd -f`  
**Fail2ban actif** : caddy-terminal

### Workout Tracker (Suivi musculation PPL)

**URL** : https://workout.leblais.net  
**Installation** : `/var/www/workout`  
**Type** : HTML statique avec localStorage  
**Synchronisation** : API PHP backend  

**Fichiers importants** :
- `index.html` : Application frontend
- `api.php` : Backend synchronisation
- `data/workout-data.json` : Données synchronisées (20 Ko)
- `data/*.backup.json` : Backups automatiques

**Programme** : Push/Pull/Legs (PPL) avec stats avancées

### Dashboard Fail2ban

**URL** : https://fail2ban.leblais.net  
**Installation** : `/var/www/fail2ban-stats`  
**Type** : HTML généré dynamiquement  
**Script** : `/var/www/fail2ban-stats/generate_stats.py`  
**Données** : `/var/www/fail2ban-stats/data/stats.json`  
**Mise à jour** : Auto toutes les heures via cron  
**Fail2ban actif** : fail2ban-stats (auto-protection)

**Fonctionnalités** :
- Stats globales (jails, IPs bannies, tentatives)
- Graphiques : Top pays, bans par jour/heure
- Tableau top 20 IPs avec géolocalisation
- Design moderne avec cartes colorées

---

## 🔄 Torrents + VPN

### ruTorrent + rtorrent + ProtonVPN

**URL** : https://torrent.leblais.net  
**Installation** : `/opt/rutorrent`  
**Port rtorrent** : 6881  
**Port ruTorrent** : 8082  

**Configuration rtorrent** : `/home/rutorrent/.rtorrent.rc`  
**Session rtorrent** : `/home/rutorrent/.session`  
**Téléchargements** : `/mnt/WD_Freebox/downloads/`  
**Logs** : `/var/log/rtorrent.log`

**VPN** : ProtonVPN (OpenVPN)  
**Namespace** : `vpn` (isolation complète)  
**Kill switch** : Automatique (rtorrent s'arrête si VPN down)  
**IP publique Free** : Jamais exposée sur trackers ✅  
**Check VPN** : Script toutes les 5 min → Push Uptime Kuma

**Fail2ban actif** : caddy-torrent

---

## 🔒 VPN WireGuard

**Port** : 51820/UDP  
**Réseau VPN** : 10.8.0.0/24  
**IP serveur VPN** : 10.8.0.1  
**IP client mobile** : 10.8.0.2  
**Configuration** : `/etc/wireguard/wg0.conf`  
**Split tunneling** : 192.168.1.0/24 + 10.8.0.0/24  
**DNS** : 10.8.0.1 (Pi-hole)

**Clients configurés** : 1 (mobile Android)

---

## 💾 Backups Automatiques

### Script de backup complet

**Emplacement** : `/usr/local/bin/backup-vm.sh`  
**Exécution** : Cron quotidien à 3h du matin  
**Logs** : `/var/log/backup-vm.log`  
**Taille backup** : ~66-107 MB compressé

**Services sauvegardés** :
- Configurations système : Caddy, Fail2ban, WireGuard, UFW, SSH, fstab
- Authelia : Config + base SQLite
- Docker : Configurations de tous les containers
- Nextcloud : Configuration (données sur SMB)
- ProtonVPN : Config OpenVPN
- Services systemd : Tous les services custom
- Scripts custom : Tout `/usr/local/bin`
- rtorrent + ruTorrent : Config + session
- Sites web : Tous les sites `/var/www`
- Pi-hole : Configuration + bases SQLite
- Vaultwarden : Base de données SQLite
- Uptime Kuma : Base de données + configuration
- Linkding : Base de données + bookmarks
- Actual Budget : Base de données
- Crontabs : User + root
- Credentials : SMB, OVH API, rclone (chiffrement)
- Listes : Paquets, services, règles UFW
- Infos système : Disques, RAM, réseau

**Stockage backups** :
- **Local** : `/mnt/WD_Freebox/backups/vm-debian` (30 derniers)
- **Google Drive** : `gdrive-crypt:` chiffré E2EE (30 derniers)

**Rétention** : 30 jours

### rclone + Google Drive + Chiffrement E2EE

**Installation** : rclone 1.60.1  
**Configuration** : `/root/.config/rclone/rclone.conf`

**Remotes** :
- `gdrive` : Google Drive (OAuth2)
- `gdrive-crypt` : Chiffrement E2EE sur `gdrive:Backups/VM-Debian/`

**Chiffrement** :
- Algorithme : AES-256 (NaCl SecretBox)
- Noms fichiers : Chiffrés
- Contenu : Chiffré
- Clés : Stockées dans rclone.conf (sauvegardées)

**Même Google ne peut pas lire les backups** ✅

---

## ⚙️ Système

### Crontab Root

**Backups** :
```bash
0 3 * * * /usr/local/bin/backup-vm.sh >> /var/log/backup-vm.log 2>&1
```

**Pi-hole** :
```bash
0 4 1 * * /usr/local/bin/update-geoip.sh >> /var/log/geoip-update.log 2>&1
0 6 * * 0 /usr/local/bin/check-pihole-update.sh >> /var/log/pihole-update-check.log 2>&1
```

**VPN** :
```bash
*/5 * * * * /usr/local/bin/check-vpn-status.sh && curl -s "https://uptime.leblais.net/api/push/XXX?status=up&msg=VPN_OK" || curl -s "https://uptime.leblais.net/api/push/XXX?status=down&msg=VPN_DOWN"
```

**Nextcloud Maintenance** :
```bash
0 2 */20 * * /usr/local/bin/nextcloud-maintenance.sh
30 2 * * 1 sudo -u postgres psql -d nextcloud -c "VACUUM ANALYZE;" >> /var/log/nextcloud-maintenance.log 2>&1
0 9 * * 1 /usr/local/bin/nextcloud-check-update.sh
0 */6 * * * /usr/local/bin/nextcloud-health-check.sh
0 1 * * * free -h >> /var/log/nextcloud-ram-daily.log
```

**Nextcloud Background Jobs (CRITIQUE avec timeout)** :
```bash
*/5 * * * * timeout 600 sudo -u www-data php -f /var/www/nextcloud/cron.php
```

**Nextcloud Cleanup Verrous (Nouveau)** :
```bash
0 * * * * /usr/local/bin/nextcloud-cleanup-locks.sh
```

### RAM Usage

**Utilisation actuelle** :
- Système : ~400 MB
- Services Docker : ~200 MB
- Nextcloud (PHP-FPM + PostgreSQL + Redis) : ~280 MB
- Autres services : ~200 MB
- **Total** : ~1.1 GB / 2 GB
- **Disponible** : ~500-800 MB ✅

**Optimisations appliquées** :
- PHP-FPM : 5 workers max (au lieu de 10)
- PostgreSQL : 64 MB shared_buffers (au lieu de 128 MB)
- Redis : 64 MB maxmemory (au lieu de 100 MB)
- Nextcloud previews : Désactivés
- Apps non essentielles : Désactivées

### Montages SMB

**Freebox 1 TB** : `/mnt/WD_Freebox`
```
//192.168.1.254/Disque\040dur/VM-Debian /mnt/WD_Freebox cifs credentials=/etc/samba/freebox-creds,uid=1000,gid=1000,file_mode=0755,dir_mode=0755,iocharset=utf8 0 0
```

**Nextcloud data** : `/mnt/WD_Freebox/nextcloud-data/`  
**Backups** : `/mnt/WD_Freebox/backups/vm-debian/`  
**Downloads** : `/mnt/WD_Freebox/downloads/`

---

## 📝 Procédures Récurrentes

### Ajout d'un service web derrière Caddy

1. Installer le service (Docker ou système)
2. Créer sous-domaine DNS chez OVH
3. Ajouter reverse_proxy dans `/etc/caddy/Caddyfile` :
```
subdomain.leblais.net {
    log {
        output file /var/log/caddy/subdomain-access.log
    }
    reverse_proxy 127.0.0.1:PORT
}
```
4. Tester : `sudo caddy validate --config /etc/caddy/Caddyfile`
5. Appliquer : `sudo systemctl restart caddy`
6. Créer filtre Fail2ban si authentification
7. Ajouter à `backup-vm.sh`
8. Ajouter monitor Uptime Kuma

### Ajout d'un service Docker

1. Créer répertoire : `sudo mkdir -p /opt/nom_service`
2. Créer `docker-compose.yml`
3. Configurer ports : `127.0.0.1:PORT:PORT_INTERNE`
4. Créer sous-domaine DNS OVH
5. Ajouter reverse_proxy Caddyfile
6. Démarrer : `docker-compose up -d`
7. Ajouter à backup-vm.sh
8. Ajouter à Uptime Kuma

### Mise à jour système

```bash
# Updates système
sudo apt update && sudo apt upgrade -y

# Updates Docker images
cd /opt/SERVICE && docker-compose pull && docker-compose up -d

# Nextcloud (via web interface ou occ)
sudo -u www-data php /var/www/nextcloud/occ update:check
```

### Résolution problèmes Nextcloud

**Symptômes** : Cron bloqué, consommation CPU élevée, scans qui ne terminent pas

**Diagnostic** :
```bash
# Vérifier processus cron actifs
ps aux | grep "nextcloud/cron.php" | grep -v grep

# Vérifier logs
tail -100 /mnt/WD_Freebox/nextcloud-data/nextcloud.log
tail -50 /var/log/nextcloud-cleanup.log
```

**Solutions** :
```bash
# 1. Killer processus bloqué (si existe)
kill -9 PID

# 2. Nettoyer verrous PostgreSQL
sudo -u postgres psql -d nextcloud
DELETE FROM oc_file_locks WHERE ttl < EXTRACT(EPOCH FROM NOW());
UPDATE oc_jobs SET reserved_at = 0 WHERE reserved_at > 0;
\q

# 3. Tester cron manuellement
sudo -u www-data php -f /var/www/nextcloud/cron.php

# 4. Vérifier RAM disponible
free -h
```

**Prévention** :
- ✅ Script cleanup automatique toutes les heures
- ✅ Timeout 10 min sur le cron principal
- ✅ Health check avec détection cron bloqué
- ✅ Monitoring Uptime Kuma

---

## 🛠️ Outils Préférés

**Éditeur console** : VIM (remplace nano dans toutes les instructions)

---

## 📊 Statistiques Infrastructure

**Services auto-hébergés** : 15+  
**Domaines actifs** : 15+ sous-domaines  
**Jails Fail2ban** : 13  
**Monitors Uptime Kuma** : 15+  
**RAM utilisée** : ~1.1 GB / 2 GB (55%)  
**Stockage VM** : ~12 GB / 32 GB  
**Stockage externe** : ~240 GB / 1 TB (Nextcloud + downloads)  
**Uptime moyen** : 99.9%  
**Backup quotidien** : ✅ Local + Cloud chiffré  
**SSL** : ✅ Tous les services (Let's Encrypt)  
**Sécurité** : A+ (SSL Labs, Fail2ban actif)

---

## ✅ Prochaines Étapes

**Court terme** :
- [ ] DD externe 1 TB → Backup local (remplacer Google Drive)
- [ ] Compte utilisateur Jerome sur Nextcloud
- [ ] Client desktop Nextcloud sur PC famille

**Moyen terme** :
- [ ] Évaluer OnlyOffice sur VPS (si besoin édition collaborative)
- [ ] Partages inter-utilisateurs Nextcloud
- [ ] Notifications Gotify (si besoin centraliser alertes)

**Long terme** :
- [ ] Migration VM vers ARM64 plus puissant (4-8 GB RAM) ?
- [ ] NAS dédié pour stockage ?

---

## 🎓 Leçons Apprises

**RAM** :
- 2 GB suffisants pour 15+ services si bien optimisé
- Background jobs accumulés peuvent saturer (18k+ jobs nettoyés)
- Previews photos = gros consommateur RAM (désactivé)
- Pics RAM temporaires normaux (scan, maintenance)

**Nextcloud** :
- `cron.php` > `occ background:cron` (plus compatible)
- **Timeout obligatoire** sur le cron (600s = 10 min)
- **Cleanup automatique verrous** indispensable (toutes les heures)
- Scan progressif > Scan complet (gestion RAM)
- Doublons = 50 GB économisés (analyse intelligente importante)
- PostgreSQL + Redis = Meilleure performance que MySQL
- **902 verrous** accumulés lors de la migration initiale

**Sécurité** :
- Fail2ban indispensable (tentatives quotidiennes)
- Chiffrement E2EE backups = Tranquillité
- SSL partout = Non négociable
- Authelia = SSO simple et efficace

**Architecture** :
- ARM64 compatible si attention aux binaires
- SMB mount stable et performant
- Docker = Isolation et facilité updates
- Monitoring 24/7 = Détection précoce problèmes

**Backup** :
- 3-2-1 rule : 3 copies, 2 supports, 1 hors site ✅
- Automatisation critique (erreur humaine)
- Chiffrement E2EE = Protection même contre hébergeur
- Rétention 30 jours = Bon compromis

**Résolution problèmes** :
- Logs = Premier réflexe (journalctl, tail)
- Verrous PostgreSQL = Cause fréquente blocages Nextcloud
- Timeout sur scripts critiques = Évite blocages prolongés
- Cleanup préventif > Intervention manuelle

---

**Dernière mise à jour : 16 novembre 2025**  
**Nextcloud opérationnel depuis : 13 novembre 2025**  
**Correctifs verrous appliqués : 16 novembre 2025**  
**Infrastructure stable et optimisée pour 3 utilisateurs familiaux** ✅

📝 Résumé de la session du 17 novembre 2025
🎯 Objectifs accomplis
1️⃣ Mise à jour Uptime Kuma (v1 → v2)
Problème initial : Notification de mise à jour disponible dans l'interface Uptime Kuma.
Solution appliquée :

Modifié /opt/uptime-kuma/docker-compose.yml : changement du tag image: louislam/uptime-kuma:1 vers image: louislam/uptime-kuma:2
Téléchargé la nouvelle image : docker-compose pull
Recréé le container : docker-compose up -d
Migration automatique de la base de données SQLite effectuée (durée ~5 min)

Résultat : ✅ Uptime Kuma v2.0.2 opérationnel, tous les monitors préservés

2️⃣ Correction du script check-pihole-update.sh
Problème initial : Le script s'exécutait (logs OK) mais aucun push n'arrivait sur Uptime Kuma depuis le 07/11.
4 bugs identifiés et corrigés :
Bug #1 - URL malformée avec double ?

Cause : UPTIME_PUSH_URL contenait déjà ?status=up&msg=OK&ping= et la fonction ajoutait encore ?status=...
Fix : Nettoyé l'URL de base → https://uptime.leblais.net/api/push/FQd5HEJnWf

Bug #2 - Caractères spéciaux non encodés

Cause : Messages avec espaces, :, et autres caractères spéciaux cassaient l'URL
Fix : Utilisé curl -G --data-urlencode pour encoder automatiquement les paramètres

Bug #3 - Parenthèses dans l'extraction des versions

Cause : grep -o "Latest:.*" | awk '{print $2}' capturait v6.2.2) au lieu de v6.2.2
Fix : Ajouté tr -d '()' pour nettoyer les parenthèses

Bug #4 - Casse incorrecte dans le grep

Cause : Script utilisait "Version is" (V majuscule) alors que pihole retourne "version is" (v minuscule)
Fix : Changé en "version is" (minuscule)

Résultat : ✅ Script fonctionnel, push Uptime Kuma opérationnel, cron hebdomadaire (dimanche 6h) validé
Emplacement : /usr/local/bin/check-pihole-update.sh

3️⃣ Synchronisation et mise à jour du repo GitHub
Fichiers ajoutés au repo :
scripts/
├── check-pihole-update.sh (corrigé)
├── check-vpn-status.sh
├── nextcloud-check-update.sh
├── nextcloud-cleanup-locks.sh
├── nextcloud-health-check.sh
└── nextcloud-maintenance.sh

docker-compose/
└── uptime-kuma.yml (v1 → v2)

configs/
├── caddy/Caddyfile (màj 13/11)
├── authelia/configuration.yml (màj 10/11)
├── fail2ban/jail.local (màj 13/11)
└── fail2ban/filter.d/
    ├── caddy-files.conf (NOUVEAU - Filebrowser)
    └── caddy-nextcloud.conf (NOUVEAU - Nextcloud)

web/
├── workout/index.html (màj 16/11)
├── vault/index.html (màj 13/11)
└── fail2ban-stats/
    ├── generate_stats.py (màj 11/11)
    └── index.html (NOUVEAU)
Commits effectués :

Mise à jour Uptime Kuma v2 et ajout scripts monitoring (7 fichiers, 203 insertions)
Mise à jour configs et apps web récentes (5 fichiers)


4️⃣ Automatisation de la synchronisation GitHub
Script créé : /usr/local/bin/sync-claude-repo.sh
Fonctionnalités :

Copie automatique des configs importantes (/etc/caddy, /etc/authelia, /etc/fail2ban)
Copie des scripts depuis /usr/local/bin/
Copie des docker-compose depuis /opt/*/
Copie des apps web (/var/www/workout, /var/www/vault, /var/www/fail2ban-stats)
Détection automatique des changements via git status
Commit automatique avec message daté
Push automatique vers GitHub
Logging dans /var/log/sync-claude-repo.log

Configuration SSH :

Clé SSH Ed25519 générée : ~/.ssh/id_ed25519
Clé publique ajoutée à GitHub : "clé ssh terminal VM"
Remote Git changé de HTTPS vers SSH : git@github.com:marecaillefrederic-lab/claude.git

Cron configuré :
bash30 3 * * * /usr/local/bin/sync-claude-repo.sh >> /var/log/sync-claude-repo.log 2>&1
Exécution : Tous les jours à 3h30 du matin (après backup-vm.sh à 3h00)
Résultat : ✅ Repo GitHub automatiquement synchronisé quotidiennement, garantissant des infos toujours à jour pour les conversations avec Claude

📊 Workflow Git établi
Mise à jour manuelle (si besoin avant le cron) :
bashsudo cp fichiers_modifiés ~/claude/...
sudo chown freebox:freebox ~/claude/...
cd ~/claude
git status
git add .
git commit -m "Description des changements"
git push origin main
Mise à jour automatique : Script sync-claude-repo.sh via cron quotidien ✅

🎓 Commandes Git utiles apprises
bashgit add .                           # Ajoute tous les fichiers
git add dossier/                    # Ajoute tout un dossier
git diff                            # Voir changements avant commit
git diff --staged                   # Voir ce qui sera commité
git restore --staged fichier        # Retirer du staging
git remote -v                       # Voir URL du remote
git remote set-url origin <URL>     # Changer l'URL du remote

✅ État final de l'infrastructure
Services mis à jour :

✅ Uptime Kuma v2.0.2
✅ Script Pi-hole update check opérationnel
✅ Repo GitHub à jour et auto-synchronisé

Automatisations actives :

✅ Backup VM quotidien (3h00)
✅ Sync GitHub quotidien (3h30)
✅ Check Pi-hole update (dimanche 6h)
✅ Check VPN status (toutes les 5 min)
✅ Maintenance Nextcloud (tous les 20 jours)

Monitoring opérationnel :

✅ 15+ monitors Uptime Kuma actifs
✅ Disponibilité : 99.9%


Dernière mise à jour de cette section : 17 novembre 2025
