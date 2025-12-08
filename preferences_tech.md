# Préférences Techniques - Infrastructure leblais.net

**Mise à jour** : 08 décembre 2025

---

## 🏗️ Architecture Globale

### Infrastructure distribuée sur 2 machines :

1. **Trigkey N150** (Serveur principal - Production)
   - 16 GB RAM DDR5, Intel N150
   - Debian 13 (Trixie)
   - 13+ services Docker + natifs
   - Services 24/7 accessibles via sous-domaines

2. **VPS OVH** (Backup + Monitoring + VM Desktop)
   - 8 GB RAM, 75 GB SSD
   - Debian 13 (Trixie)
   - Monitoring externe + Backups + VM bureautique
   - IP publique : 151.80.59.35

---

## 🖥️ **VM Desktop sur VPS OVH**

### Caractéristiques VM

**Hyperviseur** : KVM/libvirt  
**Nom VM** : `desktop-vm`  
**OS** : Debian 13 (Trixie) + Xfce  
**RAM** : 5 GB (5120 MB)  
**vCPU** : 2 cœurs  
**Stockage** : 40 GB (qcow2, expansion dynamique)  
**Réseau** : NAT via virbr0 (192.168.122.x)  
**Accès** : https://desktop-vps.leblais.net (noVNC web)

### Usage

- **Bureautique légère** : LibreOffice, Firefox
- **Formation Python** : Python 3.11+, pip, venv, VS Code/PyCharm Community
- **Stockage docs** : Client Nextcloud (sync auto vers cloud.leblais.net)
- **Accès** : Depuis n'importe quel navigateur web

### Commandes de gestion

```bash
# Lister toutes les VMs
sudo virsh list --all

# Démarrer la VM
sudo virsh start desktop-vm

# Éteindre proprement
sudo virsh shutdown desktop-vm

# Forcer l'arrêt
sudo virsh destroy desktop-vm

# Redémarrer
sudo virsh reboot desktop-vm

# Voir infos VM
sudo virsh dominfo desktop-vm

# Voir port VNC
sudo virsh vncdisplay desktop-vm

# Console texte (Ctrl+] pour sortir)
sudo virsh console desktop-vm

# Activer autostart (déjà fait)
sudo virsh autostart desktop-vm
```

### Alias zsh configuré

```bash
# Dans ~/.zshrc
alias startvm='sudo virsh start desktop-vm && echo "VM démarrée, connecte-toi sur https://desktop-vps.leblais.net"'
```

### Gestion noVNC/websockify

```bash
# Démarrer websockify (accès web)
websockify -D --web=/usr/share/novnc/ 6080 localhost:5900

# Vérifier que websockify tourne
ps aux | grep websockify

# Tuer websockify
pkill websockify

# Relancer websockify
websockify -D --web=/usr/share/novnc/ 6080 localhost:5900
```

### Configuration Caddy VPS

**Caddyfile VPS** (`/etc/caddy/Caddyfile`) :

```caddy
# VM Desktop - noVNC
desktop-vps.leblais.net {
    # Rediriger la racine vers /vnc.html
    redir / /vnc.html
    
    # Proxy inverse pour noVNC
    reverse_proxy localhost:6080
}

# Uptime Kuma VPS
uptime-vps.leblais.net {
    reverse_proxy localhost:3001
}
```

### Logiciels installés dans la VM

**Bureautique** :
- LibreOffice (Writer, Calc, Impress)
- Firefox (navigateur)
- Lecteur PDF

**Développement Python** :
- Python 3.11+
- pip, virtualenv
- VS Code ou PyCharm Community Edition
- Git

**Synchronisation** :
- Client Nextcloud Desktop (sync automatique des documents)

### Résolution d'écran

**Modifier la résolution** (depuis la VM) :

```bash
# Via interface graphique Xfce
Applications → Settings → Display → Choisir 1920x1080 ou 1600x900

# Via ligne de commande (si besoin)
sudo vim /etc/default/grub
# Ajouter : GRUB_GFXMODE=1920x1080
# Puis : sudo update-grub && sudo reboot
```

### Troubleshooting

**Problème : VM ne démarre pas**
```bash
# Vérifier l'état
sudo virsh list --all

# Voir les logs
sudo cat /var/log/libvirt/qemu/desktop-vm.log

# Redémarrer libvirtd
sudo systemctl restart libvirtd

# Redémarrer la VM
sudo virsh start desktop-vm
```

**Problème : noVNC ne se connecte pas**
```bash
# Vérifier que websockify tourne
ps aux | grep websockify

# Relancer websockify
pkill websockify
websockify -D --web=/usr/share/novnc/ 6080 localhost:5900

# Vérifier le port VNC de la VM
sudo virsh vncdisplay desktop-vm
```

**Problème : VM éteinte après shutdown**
```bash
# C'est normal ! Autostart = démarre au boot du VPS, pas après shutdown manuel
# Pour redémarrer : sudo virsh start desktop-vm
# Ou utiliser l'alias : startvm
```

---

## 🐳 **Services Docker sur Trigkey N150**

### Liste complète des services

**Cloud & Productivité** :
- **Nextcloud** + OnlyOffice : Cloud familial (290 GB, 2 users)
- **Vaultwarden** : Gestionnaire mots de passe
- **Linkding** : Gestionnaire bookmarks
- **File Browser** : Explorateur fichiers téléchargés

**Monitoring & Sécurité** :
- **Uptime Kuma** : Monitoring services 24/7
- **Netdata** : Monitoring système temps réel
- **Dashboard Fail2ban** : Stats sécurité
- **Authelia** : SSO (Single Sign-On)

**Torrents & Média** :
- **qBittorrent** + **Gluetun** : Torrents via ProtonVPN (Pologne)
- **FreshRSS** : Agrégateur flux RSS

**Outils** :
- **Terminal Web (ttyd)** : Accès SSH via navigateur
- **Pi-hole** : Blocage pub DNS
- **Workout Tracker** : Suivi musculation PPL (HTML/JS custom)
- **Budget Tracker** : Gestion finances (HTML/JS custom)

### Architecture Docker

```
/home/frederic/
├── docker/
│   ├── nextcloud/
│   ├── vaultwarden/
│   ├── uptime-kuma/
│   ├── linkding/
│   ├── gluetun/
│   ├── qbittorrent/
│   ├── freshrss/
│   ├── authelia/
│   ├── file-browser/
│   └── netdata/
├── web/
│   ├── workout/
│   ├── budget/
│   ├── vault/
│   └── fail2ban-stats/
└── scripts/
    ├── backup-trigkey.sh
    ├── sync-claude-repo.sh
    └── ...
```

---

## 🔒 **Sécurité**

### Caddy (Reverse Proxy)

**Trigkey** : Configuration dans `/etc/caddy/Caddyfile`  
**VPS** : Configuration dans `/etc/caddy/Caddyfile`

**Fonctionnalités** :
- SSL automatique (Let's Encrypt DNS challenge OVH)
- Reverse proxy pour tous les services
- Logs JSON pour Fail2ban
- Compression automatique
- HTTP/2 & HTTP/3

### Fail2ban (Trigkey uniquement)

**13 jails actives** :
- sshd
- caddy-auth
- authelia
- nextcloud
- vaultwarden
- pihole
- freshrss
- qbittorrent
- linkding
- workout
- budget
- terminal-web
- file-browser

**Configuration** : `/etc/fail2ban/jail.local`  
**Filtres custom** : `/etc/fail2ban/filter.d/`

### Authelia (SSO)

**Services protégés** :
- Terminal Web (ttyd)
- Workout Tracker
- Budget Tracker
- Dashboard Fail2ban

**Configuration** : `/home/frederic/docker/authelia/configuration.yml`

---

## 💾 **Backups**

### Script backup quotidien (3h00)

**Fichier** : `/home/frederic/scripts/backup-trigkey.sh`

**Sauvegarde vers VPS OVH** :
- Configs Caddy, Authelia, Fail2ban
- Docker-compose de tous les services
- Configs applicatives importantes
- Scripts maintenance
- Crontabs

**Exclusions** :
- Données volumineuses (Nextcloud data déjà redondant)
- Logs
- Fichiers temporaires

**Vérification** : Login SSH sur VPS → `/root/backups/trigkey/`

---

## 🌐 **Réseau & DNS**

### Domaine principal

**leblais.net** (géré chez OVH)

### Sous-domaines Trigkey (IP locale via DDNS)

| Service | Sous-domaine |
|---------|--------------|
| Nextcloud | cloud.leblais.net |
| Vaultwarden | vaultwarden.leblais.net |
| Uptime Kuma | uptime.leblais.net |
| Terminal Web | terminal.leblais.net |
| Pi-hole | pihole.leblais.net |
| Workout | workout.leblais.net |
| Budget | budget.leblais.net |
| FreshRSS | rss.leblais.net |
| qBittorrent | torrent.leblais.net |
| Linkding | bookmarks.leblais.net |
| File Browser | files.leblais.net |
| Fail2ban Stats | fail2ban.leblais.net |
| Netdata | monitoring.leblais.net |

### Sous-domaines VPS (IP publique 151.80.59.35)

| Service | Sous-domaine |
|---------|--------------|
| VM Desktop | desktop-vps.leblais.net |
| Uptime Kuma VPS | uptime-vps.leblais.net |

### Configuration DNS OVH

**Enregistrements A** :
- `*.leblais.net` → IP Trigkey (via DDNS)
- `desktop-vps.leblais.net` → 151.80.59.35
- `uptime-vps.leblais.net` → 151.80.59.35

---

## 📊 **Monitoring**

### Uptime Kuma (2 instances)

**Instance locale (Trigkey)** :
- URL : https://uptime.leblais.net
- Monitore : Tous les services Trigkey
- Notifications : Email + SMS

**Instance externe (VPS)** :
- URL : https://uptime-vps.leblais.net
- Monitore : Services Trigkey depuis l'extérieur
- Alertes : SMS si Trigkey down

### Netdata

**URL** : https://monitoring.leblais.net  
**Métriques** : CPU, RAM, disque, réseau, Docker containers

---

## 🔧 **Commandes Utiles**

### Docker (Trigkey)

```bash
# Voir tous les containers
docker ps -a

# Logs d'un container
docker logs -f <container_name>

# Redémarrer un container
docker restart <container_name>

# Entrer dans un container
docker exec -it <container_name> bash

# Voir l'utilisation ressources
docker stats
```

### Caddy

```bash
# Trigkey
sudo systemctl status caddy
sudo systemctl reload caddy
sudo journalctl -u caddy -f

# VPS
sudo systemctl status caddy
sudo systemctl reload caddy
sudo journalctl -u caddy -f
```

### Fail2ban (Trigkey)

```bash
# Statut général
sudo fail2ban-client status

# Statut d'une jail
sudo fail2ban-client status <jail_name>

# Débannir une IP
sudo fail2ban-client set <jail_name> unbanip <IP>

# Voir les bans actifs
sudo fail2ban-client banned
```

### Nextcloud

```bash
# Scan fichiers
docker exec -u www-data nextcloud php occ files:scan --all

# Maintenance mode
docker exec -u www-data nextcloud php occ maintenance:mode --on
docker exec -u www-data nextcloud php occ maintenance:mode --off

# Mise à jour
docker exec -u www-data nextcloud php occ upgrade
```

### OnlyOffice Document Server

**URL** : https://office.leblais.net  
**Port interne** : 127.0.0.1:8088→80  
**Image Docker** : onlyoffice/documentserver:latest  
**Conteneur** : `onlyoffice`

**Configuration JWT** :
- JWT activé pour sécurité
- Secret partagé avec Nextcloud
- Documentation complète : `docs/onlyoffice-config.md`

**Commandes utiles** :
```bash
# Status
docker ps | grep onlyoffice

# Healthcheck
curl -k https://office.leblais.net/healthcheck

# Logs
docker logs onlyoffice

# Récupérer JWT Secret
docker inspect onlyoffice | grep JWT_SECRET
```

**Troubleshooting** : Voir `docs/troubleshooting-onlyoffice.md`

---

## 🎯 **Workflow Ajout Service**

### Sur Trigkey

1. Créer dossier dans `/home/frederic/docker/<service>/`
2. Créer `docker-compose.yml`
3. Lancer : `docker-compose up -d`
4. Ajouter reverse proxy dans Caddyfile
5. Créer sous-domaine DNS OVH
6. Ajouter filtre + jail Fail2ban si applicable
7. Ajouter au script `backup-trigkey.sh`
8. Créer monitor Uptime Kuma (local + VPS)
9. Lancer `sync-claude-repo.sh`

### Sur VPS

1. Installer service ou créer container
2. Ajouter reverse proxy dans Caddyfile VPS
3. Créer sous-domaine DNS OVH (→ 151.80.59.35)
4. Créer monitor Uptime Kuma VPS
5. Mettre à jour README.md et preferences_tech.md

---

## 📚 **Documentation Importante**

### Portail d'accès

**URL** : https://vault.leblais.net  
**Fichier** : `/var/www/vault/index.html`

Liste tous les services avec badges (Authelia / Login requis) et séparation Trigkey / VPS.

### Repository GitHub

**URL** : https://github.com/marecaillefrederic-lab/claude

**Synchronisation automatique** (3h30 quotidien) :
- Configs (Caddy, Authelia, Fail2ban)
- Scripts
- Docker-compose
- Documentation

---

## 💡 **Bonnes Pratiques**

### Avant tout changement majeur

1. ✅ Backup manuel si nécessaire
2. ✅ Tester en dev si possible
3. ✅ Noter les commandes dans un fichier texte
4. ✅ Faire le changement
5. ✅ Vérifier logs
6. ✅ Tester le service
7. ✅ Mettre à jour documentation
8. ✅ Lancer `sync-claude-repo.sh`

### Maintenance régulière

**Hebdomadaire** :
- Vérifier Dashboard Fail2ban
- Vérifier Uptime Kuma (2 instances)
- Vérifier espace disque

**Mensuel** :
- Mises à jour système : `sudo apt update && sudo apt upgrade`
- Mises à jour Docker images : `docker-compose pull && docker-compose up -d`
- Vérifier backups VPS

**Trimestriel** :
- Audit sécurité Nextcloud
- Révision jails Fail2ban
- Nettoyage logs anciens

---

## 🚀 **Optimisations Futures**

### Trigkey
- [ ] Backup Nextcloud data → USB externe 1 TB
- [ ] Ajout utilisateur Jerome sur Nextcloud
- [ ] Migration Pi-hole vers container Docker

### VPS
- [ ] Optimiser résolution VM Desktop (1920x1080)
- [ ] Setup complet environnement Python dans VM
- [ ] Automatiser backup snapshot VM

### Infrastructure
- [ ] Monitoring températures Trigkey
- [ ] Alertes proactives (espace disque, charge CPU)
- [ ] Documentation vidéo procédures critiques

---

**Dernière mise à jour** : 08 décembre 2025  
**Infrastructure stable et opérationnelle** ✅  
**15+ services en production** 🚀
