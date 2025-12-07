# Infrastructure Technique - leblais.net

**Dernière mise à jour : 05 décembre 2025**

---

## 🎯 Vue d'ensemble

Infrastructure auto-hébergée distribuée sur deux machines :
- **Trigkey N150** : Serveur principal (services, données)
- **VPS OVH** : Backup externe + monitoring

### Trigkey N150 (Serveur principal)

**Caractéristiques système :**
- **CPU** : Intel N150
- **RAM** : 16 GB DDR5
- **Stockage** : 500 GB SSD (système) + 1 TB SSD (données)
- **OS** : Debian 13 (Trixie)
- **Utilisateur** : frederic
- **Services** : 12+ services auto-hébergés
- **Sécurité** : A+ (SSL, Fail2ban 13 jails, Authelia)

### VPS OVH (Backup + Monitoring externe)

**Caractéristiques :**
- **Offre** : VPS-1 (4,58€/mois)
- **CPU** : 4 vCores
- **RAM** : 8 GB
- **Stockage** : 75 GB SSD
- **OS** : Debian 13
- **IP** : 151.80.59.35
- **Utilisateur** : debian
- **Rôle** : Backups trigkey + Uptime Kuma externe

---

## 📊 Nextcloud - Cloud Familial

**URL** : https://cloud.leblais.net  
**Version** : Nextcloud 32.0.2  
**Installation** : `/var/www/nextcloud`  
**Données** : `/mnt/datadisk/nextcloud-data/`  
**Base de données** : PostgreSQL 16  
**Cache** : Redis  
**Sécurité** : Rating A  
**Office** : OnlyOffice Document Server (port 8088)

### Utilisateurs

| Utilisateur | Rôle | Stockage |
|-------------|------|----------|
| frederic | Admin | ~50 GB |
| sylvie | User | ~240 GB |

### Configuration PHP-FPM

**Fichier** : `/etc/php/8.4/fpm/pool.d/www.conf`
```ini
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 8
```

### Scripts de maintenance

| Script | Fréquence | Fonction |
|--------|-----------|----------|
| `nextcloud-cleanup-locks.sh` | Toutes les heures | Nettoie verrous expirés |
| `nextcloud-maintenance.sh` | Tous les 20 jours | Maintenance complète |
| `nextcloud-health-check.sh` | Toutes les heures | Push Uptime Kuma |
| `nextcloud-check-update.sh` | Lundis 9h | Vérifie mises à jour |

### Cron Nextcloud

```bash
*/5 * * * * timeout 600 sudo -u www-data php -f /var/www/nextcloud/cron.php
```

---

## 🐳 Docker Services

### qBittorrent + Gluetun (VPN)

**URL** : https://torrent.leblais.net  
**Installation** : `/opt/rutorrent`  
**VPN** : Gluetun avec WireGuard (ProtonVPN)  
**IP VPN** : 185.132.178.126 (Pays-Bas)  
**Téléchargements** : `/mnt/datadisk/Téléchargements`

**docker-compose.yml** :
```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=custom
      - VPN_TYPE=wireguard
    ports:
      - "8082:8080"
      - "6881:6881"
      - "6881:6881/udp"
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
      - WEBUI_PORT=8080
    volumes:
      - /opt/rutorrent/qbittorrent-config:/config
      - /mnt/datadisk/Téléchargements:/downloads
    restart: unless-stopped
```

### Vaultwarden

**URL** : https://vaultwarden.leblais.net  
**Installation** : `/opt/vaultwarden`  
**Port** : 8080

### Uptime Kuma (local)

**URL** : https://uptime.leblais.net  
**Installation** : `/opt/uptime-kuma`  
**Port** : 3001  
**Monitors** : 15+ services

### Linkding

**URL** : https://bookmarks.leblais.net  
**Installation** : `/opt/linkding`  
**Port** : 9092

### OnlyOffice Document Server

**URL** : https://office.leblais.net  
**Port** : 8088

### File Browser

**URL** : https://files.leblais.net  
**Port** : 8081

---

## 🌐 Services Web (PHP)

### FreshRSS

**URL** : https://rss.leblais.net  
**Installation** : `/var/www/freshrss`

### Budget Tracker

**URL** : https://budget.leblais.net  
**Installation** : `/var/www/budget`  
**Protection** : Authelia

### Workout Tracker

**URL** : https://workout.leblais.net  
**Installation** : `/var/www/workout`  
**Protection** : Authelia

### Dashboard Fail2ban

**URL** : https://fail2ban.leblais.net  
**Installation** : `/var/www/fail2ban-stats`  
**Script** : `generate_stats.py` (cron toutes les heures)

### Portail Vault

**URL** : https://vault.leblais.net  
**Installation** : `/var/www/vault`

---

## 🔒 Sécurité

### Caddy (Reverse Proxy)

**Configuration** : `/etc/caddy/Caddyfile`  
**Logs JSON** : `/var/log/caddy/*.log`  
**SSL** : Let's Encrypt via DNS challenge OVH  
**Credentials** : `/etc/caddy/caddy.env`

### Fail2ban

**Configuration** : `/etc/fail2ban/jail.local`  
**Filtres** : `/etc/fail2ban/filter.d/caddy-*.conf`

**13 Jails actives :**
- sshd (port 24589)
- caddy-terminal
- caddy-workout
- caddy-freshrss
- caddy-torrent
- caddy-pihole
- caddy-vaultwarden
- caddy-uptime
- caddy-bookmarks
- caddy-budget
- caddy-files
- caddy-nextcloud
- fail2ban-stats (META)

### Authelia (SSO)

**URL** : https://auth.leblais.net  
**Configuration** : `/etc/authelia/configuration.yml`  
**Port** : 9091

### Pi-hole

**URL** : https://pihole.leblais.net  
**Port** : 8053

---

## 💾 Backups

### Trigkey → VPS OVH

**Script** : `/usr/local/bin/backup-trigkey.sh`  
**Fréquence** : Quotidien à 3h  
**Destination** : `vps:/home/debian/backups/trigkey/`  
**Rétention** : 30 jours  
**Taille** : ~35 MB compressé

**Contenu sauvegardé :**
- Configurations : Caddy, Fail2ban, WireGuard, SSH, Authelia, Pi-hole
- Apps : Nextcloud config, Vaultwarden, Uptime Kuma, Linkding, FreshRSS
- PostgreSQL dump Nextcloud
- Scripts `/usr/local/bin/*.sh`
- Crontabs, dotfiles
- Sites web `/var/www/`

### Données Nextcloud → USB 1 TB

**À configurer** : Backup des données Nextcloud (290 GB) vers disque USB externe

---

## 📡 Monitoring

### Beszel (Monitoring système + SMART)

**URL** : https://monitoring.leblais.net  
**Version** : 0.17.0  
**Installation** : `/opt/beszel`

**Systèmes monitorés** :

| Système | Hôte/IP | Port | Type agent |
|---------|---------|------|------------|
| trigkey-n150 | 172.17.0.1 | 45876 | systemd natif |
| vps-ovh | 151.80.59.35 | 45876 | systemd natif |

**Fonctionnalités** :
- Monitoring CPU, RAM, disque, réseau
- Températures système (CPU, NVMe, RAM)
- **Données S.M.A.R.T.** des disques (Trigkey uniquement)
- Monitoring containers Docker
- Alertes configurables

**Disques SMART monitorés (Trigkey)** :

| Appareil | Modèle | Capacité | Type | Heures | Cycles |
|----------|--------|----------|------|--------|--------|
| /dev/nvme0 | WD_BLACK SN770 1TB | 931.5 GB | NVMe | 11301h | 52 |
| /dev/sda | 512GB SSD | 476.9 GB | SATA | 202h | 10 |

**Note** : Le VPS OVH n'a pas de données SMART (disque virtualisé).

---

#### Configuration Hub (Trigkey)

**Fichier** : `/opt/beszel/docker-compose.yml`

```yaml
services:
  beszel:
    image: henrygd/beszel:latest
    container_name: beszel
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./beszel_data:/beszel_data
    environment:
      - LISTEN=127.0.0.1:8090
```

---

#### Configuration Agent Trigkey (systemd)

**Fichier** : `/etc/systemd/system/beszel-agent.service`

```ini
[Unit]
Description=Beszel Agent
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=45876"
Environment="KEY=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEevsCCEm6yvr9073DzKk5gjiEgtB92pXQ57DayD8Jf"
ExecStart=/usr/local/bin/beszel-agent
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Prérequis SMART** :
- `smartmontools` installé (`apt install smartmontools`)
- Agent en binaire natif (pas Docker) pour accès `/dev/*`

---

#### Configuration Agent VPS OVH (systemd)

**Fichier** : `/etc/systemd/system/beszel-agent.service`

```ini
[Unit]
Description=Beszel Agent
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=45876"
Environment="KEY=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEevsCCEm6yvr9073DzKk5gjiEgtB92pXQ57DayD8Jf"
ExecStart=/usr/local/bin/beszel-agent
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Firewall VPS** (ufw) :
```bash
sudo ufw allow from 82.67.173.61 to any port 45876 proto tcp
```

---

#### Commandes utiles Beszel

```bash
# === TRIGKEY ===
# Status agent
sudo systemctl status beszel-agent

# Logs agent
journalctl -u beszel-agent -f

# Redémarrer agent
sudo systemctl restart beszel-agent

# Status hub
docker logs beszel --tail 50

# Mise à jour agent
sudo beszel-agent update

# === VPS ===
ssh vps
sudo systemctl status beszel-agent
sudo beszel-agent update
```

---

### Uptime Kuma local (Trigkey)

**URL** : https://uptime.leblais.net  
**Monitors** : Tous les services internes  
**Alertes** : SMS

### Uptime Kuma externe (VPS)

**URL** : http://151.80.59.35:3001  
**Rôle** : Monitorer le trigkey depuis l'extérieur  
**Sonde** : TCP port 24589 (SSH) sur 82.67.173.61  
**Alertes** : SMS

---

## ⚙️ Crontab Root

```bash
# VPN Check - Toutes les 5 minutes
*/5 * * * * /usr/local/bin/check-vpn-status.sh >> /var/log/check-vpn.log 2>&1

# GeoIP Update - 1er du mois
0 4 1 * * /usr/local/bin/update-geoip.sh >> /var/log/geoip-update.log 2>&1

# Pi-hole Update Check - Dimanche 6h
0 6 * * 0 /usr/local/bin/check-pihole-update.sh >> /var/log/pihole-update-check.log 2>&1

# PostgreSQL VACUUM - Lundis 2h30
30 2 * * 1 sudo -u postgres psql -d nextcloud -c "VACUUM ANALYZE;" >> /var/log/nextcloud-maintenance.log 2>&1

# Nextcloud Cleanup Locks - Toutes les heures
0 * * * * /usr/local/bin/nextcloud-cleanup-locks.sh

# Nextcloud Maintenance - Tous les 20 jours
0 2 */20 * * /usr/local/bin/nextcloud-maintenance.sh

# Nextcloud Check Update - Lundis 9h
0 9 * * 1 /usr/local/bin/nextcloud-check-update.sh

# Nextcloud Health Check - Toutes les heures
0 * * * * /usr/local/bin/nextcloud-health-check.sh

# Nextcloud Cron - Toutes les 5 minutes
*/5 * * * * timeout 600 sudo -u www-data php -f /var/www/nextcloud/cron.php

# Backup Trigkey → VPS - 3h
0 3 * * * /usr/local/bin/backup-trigkey.sh >> /var/log/backup-trigkey.log 2>&1

# Fail2ban Stats - Toutes les heures
0 * * * * cd /var/www/fail2ban-stats && ./generate_stats.py >> /var/log/fail2ban-stats-cron.log 2>&1
```

---

## 🔧 Accès SSH

### Trigkey

**Domaine** : trigkey.leblais.net  
**Port** : 24589  
**User** : frederic  
**Clé** : `~/.ssh/id_ed25519`

### VPS OVH

**IP** : 151.80.59.35  
**Port** : 22  
**User** : debian  
**Alias SSH** : `ssh vps` (via `~/.ssh/config`)

**~/.ssh/config :**
```
Host vps
    HostName 151.80.59.35
    User debian
    IdentityFile ~/.ssh/vps
```

---

## 📁 Arborescence Stockage

### Disque système (500 GB SSD)

```
/
├── etc/
│   ├── caddy/
│   ├── fail2ban/
│   ├── authelia/
│   ├── pihole/
│   └── wireguard/
├── opt/
│   ├── rutorrent/          # qBittorrent + Gluetun
│   ├── vaultwarden/
│   ├── uptime-kuma/
│   ├── linkding/
│   └── onlyoffice/
├── var/www/
│   ├── nextcloud/
│   ├── freshrss/
│   ├── budget/
│   ├── workout/
│   ├── vault/
│   └── fail2ban-stats/
└── home/frederic/
    └── claude/             # Repo GitHub
```

### Disque données (1 TB SSD)

```
/mnt/datadisk/
├── nextcloud-data/         # ~290 GB
└── Téléchargements/
    ├── complete/
    └── incomplete/
```

---

## 🔄 Réseau

### Ports ouverts (Freebox)

| Port externe | Port interne | Service |
|--------------|--------------|---------|
| 24589 | 24589 | SSH |
| 443 | 443 | HTTPS (Caddy) |
| 80 | 80 | HTTP (redirect) |

### DMZ

**IP DMZ** : 192.168.1.50 (Trigkey)

### WireGuard VPN

**Port** : 51820/UDP  
**Réseau** : 10.8.0.0/24  
**Config** : `/etc/wireguard/wg0.conf`

---

## 🛠️ Commandes Utiles

### Docker

```bash
# Voir containers
docker ps

# Logs qBittorrent
docker logs qbittorrent --tail 50

# Vérifier IP VPN
docker exec qbittorrent curl -s ifconfig.me

# Redémarrer stack torrent
cd /opt/rutorrent && docker compose restart
```

### Nextcloud

```bash
# Mode maintenance
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Scan fichiers
sudo -u www-data php /var/www/nextcloud/occ files:scan --all

# Status
curl -s https://cloud.leblais.net/status.php | jq
```

### Fail2ban

```bash
# Status
sudo fail2ban-client status

# Status d'une jail
sudo fail2ban-client status sshd

# Débannir IP
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

### Backup

```bash
# Lancer backup manuel
sudo /usr/local/bin/backup-trigkey.sh

# Voir backups sur VPS
ssh vps "ls -la /home/debian/backups/trigkey/"
```

---

## 📊 Statistiques

| Métrique | Valeur |
|----------|--------|
| Services actifs | 12+ |
| Sous-domaines | 15 |
| Jails Fail2ban | 13 |
| Monitors Uptime Kuma | 15+ |
| RAM utilisée | ~4 GB / 16 GB |
| Stockage données | ~290 GB / 1 TB |
| Backup quotidien | ✅ Trigkey → VPS |
| SSL | ✅ Tous les services |
| Uptime | 99.9% |

---

## ✅ Migration VM Freebox → Trigkey

**Date** : Décembre 2025

**Améliorations :**
- RAM : 2 GB → 16 GB (+700%)
- Stockage : 32 GB VM → 1.5 TB SSD
- CPU : ARM64 VM → Intel N150
- Torrent : rtorrent + namespace VPN → qBittorrent + Gluetun Docker
- Backup : Google Drive → VPS OVH dédié
- Monitoring : Local uniquement → Local + externe (VPS)

---

**Infrastructure stable et opérationnelle ✅**
