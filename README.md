# Infrastructure leblais.net - Documentation Complète

**Repository GitHub** : https://github.com/marecaillefrederic-lab/claude

Documentation complète de l'infrastructure auto-hébergée + profil personnel pour utilisation avec Claude AI.

---

## 📚 Structure du Repository

### 📄 `preferences_tech.md`
**Infrastructure technique complète**

Documentation de tous les services auto-hébergés sur Trigkey N150 (Debian 13) + VPS OVH :
- 🌐 **Nextcloud** : Cloud familial souverain (290 GB, 2 utilisateurs) + OnlyOffice
- 🐳 **Docker Services** : Vaultwarden, Uptime Kuma, Linkding, qBittorrent + Gluetun VPN
- 🔒 **Sécurité** : Caddy, Fail2ban (13 jails), Authelia, WireGuard VPN
- 🌍 **Services Web** : Pi-hole, Terminal Web, Workout Tracker, Budget, FreshRSS, Dashboard Fail2ban
- 💾 **Backups** : Automatiques quotidiens vers VPS OVH
- 📡 **Monitoring** : Uptime Kuma local + externe (VPS), Netdata
- 🖥️ **VM Desktop** : Debian 13 + Xfce sur VPS (bureautique + Python)

**Utilisation avec Claude** :
- Configuration détaillée de tous les services
- Scripts de maintenance et backup
- Procédures d'ajout de services
- Troubleshooting et optimisations
- Commandes utiles pour chaque service

---

### 👤 `preferences_profil.md`
**Profil personnel - Santé & Fitness**

Informations personnelles pour conseils adaptés :
- 💪 **Fitness** : Programme PPL 5x/semaine, suivi Workout Tracker
- 🍽️ **Nutrition** : Protéines + créatine (protocole ADF arrêté nov. 2025)
- 📊 **Objectifs** : Maintien < 90 kg, préservation masse musculaire
- ⚠️ **Points d'attention** : Surveillance performance, récupération, composition corporelle
- 🎯 **Recommandations** : Santé long terme, métabolisme à 46 ans

---

## 🎯 Objectif du Repository

**Permettre à Claude AI d'avoir un contexte complet** pour :

### Sur l'infrastructure technique
- ✅ Comprendre l'architecture distribuée (Trigkey + VPS)
- ✅ Proposer des solutions adaptées à la configuration
- ✅ Aider au troubleshooting avec contexte précis
- ✅ Suggérer améliorations pertinentes
- ✅ Maintenir documentation à jour

### Sur le profil personnel
- ✅ Donner conseils santé/fitness personnalisés
- ✅ Adapter recommandations à l'âge et objectifs
- ✅ Alerter si protocole inadapté
- ✅ Suggérer ajustements selon progression

---

## 🔧 Infrastructure Actuelle

### Trigkey N150 (Serveur principal)

**Caractéristiques** :
- **CPU** : Intel N150
- **RAM** : 16 GB DDR5
- **Stockage** : 500 GB SSD (système) + 1 TB SSD (données)
- **OS** : Debian 13 (Trixie)

**Services actifs (13+)** :
- Nextcloud + OnlyOffice (cloud familial 290 GB)
- Vaultwarden (passwords)
- Uptime Kuma (monitoring 24/7)
- Pi-hole (blocage pub DNS)
- Linkding (bookmarks)
- FreshRSS (agrégateur RSS)
- qBittorrent + Gluetun (torrents via VPN)
- Authelia (SSO)
- Terminal Web (ttyd)
- Workout Tracker (fitness PPL)
- Budget Tracker (finances)
- Dashboard Fail2ban (sécurité)
- File Browser
- Netdata (monitoring système)

### VPS OVH (Backup + Monitoring externe + VM Desktop)

**Caractéristiques** :
- **Offre** : VPS-1 (4,58€/mois)
- **RAM** : 8 GB
- **Stockage** : 75 GB SSD
- **IP** : 151.80.59.35
- **OS** : Debian 13 (Trixie)

**Services actifs** :
- **Uptime Kuma** (monitoring externe Trigkey)
- **Caddy** (reverse proxy avec SSL automatique)
- **KVM/libvirt** (hyperviseur pour VM)
- **VM Desktop** : Debian 13 + Xfce (5 GB RAM, 40 GB disk)
- **noVNC + websockify** (accès web à la VM)
- Réception backups quotidiens du Trigkey
- Alertes SMS si Trigkey down

**VM Desktop (desktop-vm)** :
- **OS** : Debian 13 + Xfce
- **RAM** : 5 GB (5120 MB)
- **vCPU** : 2 cœurs
- **Stockage** : 40 GB (format qcow2)
- **Réseau** : NAT via virbr0 (192.168.122.x)
- **Usage** : Bureautique légère + formation Python
- **Logiciels** : LibreOffice, Firefox, Python 3.11+, client Nextcloud
- **Accès** : https://desktop-vps.leblais.net (noVNC via navigateur web)
- **Autostart** : Activé (démarre automatiquement au boot du VPS)

**Gestion VM** :
```bash
# Commandes virsh
virsh list --all              # Lister VMs
virsh start desktop-vm        # Démarrer
virsh shutdown desktop-vm     # Éteindre proprement
virsh reboot desktop-vm       # Redémarrer
virsh autostart desktop-vm    # Activer démarrage auto
virsh vncdisplay desktop-vm   # Voir port VNC

# Alias zsh pour démarrage rapide
startvm                       # Démarre la VM
```

---

## 🔒 Sécurité

- SSL partout (Caddy + Let's Encrypt DNS challenge OVH)
- Fail2ban (13 jails actives sur Trigkey)
- Backups quotidiens Trigkey → VPS OVH
- Sync configs vers GitHub
- Score Nextcloud : Rating A
- Monitoring redondant (Trigkey + VPS)

---

## 🌐 Sous-domaines

### Trigkey N150
| Service | URL | Protection |
|---------|-----|------------|
| Nextcloud | cloud.leblais.net | Login requis |
| Vaultwarden | vaultwarden.leblais.net | Login requis |
| Uptime Kuma | uptime.leblais.net | Login requis |
| Pi-hole | pihole.leblais.net | Login requis |
| Terminal Web | terminal.leblais.net | Authelia |
| Workout Tracker | workout.leblais.net | Authelia |
| Budget | budget.leblais.net | Authelia |
| FreshRSS | rss.leblais.net | Login requis |
| qBittorrent | torrent.leblais.net | Login requis |
| Linkding | bookmarks.leblais.net | Login requis |
| File Browser | files.leblais.net | Login requis |
| Fail2ban Stats | fail2ban.leblais.net | Authelia |
| Netdata | monitoring.leblais.net | Login requis |

### VPS OVH
| Service | URL | Type |
|---------|-----|------|
| VM Desktop | desktop-vps.leblais.net | noVNC web |
| Uptime Kuma VPS | uptime-vps.leblais.net | Login requis |

---

## 📊 Statistiques

| Métrique | Trigkey N150 | VPS OVH |
|----------|--------------|---------|
| Services | 13+ | 2 (+ 1 VM) |
| RAM utilisée | ~4 GB / 16 GB | ~6 GB / 8 GB |
| Stockage Nextcloud | ~290 GB / 1 TB | - |
| VM Desktop | - | 5 GB RAM, 40 GB disk |
| Sous-domaines | 13 | 2 |
| Jails Fail2ban | 13 | - |
| Monitors Uptime Kuma | 15+ (local) | 2 (externe) |
| Backup quotidien | ✅ → VPS | ✅ Réception |
| Uptime moyen | 99.9% | 99.9% |

---

## 🚀 Utilisation avec Claude

### Chargement du contexte

**Dans un projet Claude** :
1. Ajouter ce repository GitHub
2. Claude charge automatiquement les fichiers preferences
3. Contexte complet disponible pour toutes les conversations

### Exemples de conversations

**Technique** :
- "Comment ajouter un nouveau service Docker ?"
- "Troubleshooting : le backup vers VPS a échoué"
- "Ajouter une jail Fail2ban pour un nouveau service"
- "Vérifier le status de tous les containers"
- "Comment augmenter la résolution de la VM Desktop ?"
- "Installer Python et VS Code dans la VM"

**Personnel** :
- "Recommandations nutrition pour optimiser récupération"
- "Mon poids stagne, que faire ?"
- "Adapter entraînement si fatigue chronique"

---

## 📝 Maintenance

**Synchronisation automatique** :
- Script `sync-claude-repo.sh` exécuté quotidiennement à 3h30
- Copie automatique des configs, scripts, docker-compose
- Commit et push automatiques vers GitHub

**Mise à jour manuelle recommandée** :
- **preferences_tech.md** : Après changement majeur d'architecture
- **preferences_profil.md** : Mensuellement (poids, objectifs)
- **README.md** : Si changement structure

---

## 🔒 Sécurité & Confidentialité

**⚠️ Important** : Ne JAMAIS commit de fichiers contenant :
- Mots de passe
- Tokens API
- Clés privées SSH
- Credentials OVH/ProtonVPN
- Informations bancaires

Les fichiers sensibles sont dans `.gitignore`.

---

## ✅ Checklist Ajout Service

Quand j'ajoute un nouveau service :

**Sur Trigkey :**
1. [ ] Installer et configurer le service
2. [ ] Ajouter reverse proxy dans Caddyfile
3. [ ] Créer sous-domaine DNS OVH
4. [ ] Ajouter log JSON pour Fail2ban
5. [ ] Créer filtre + jail Fail2ban
6. [ ] Ajouter au script backup-trigkey.sh
7. [ ] Créer monitor Uptime Kuma (local + VPS)
8. [ ] **Lancer sync-claude-repo.sh**

**Sur VPS :**
1. [ ] Installer et configurer le service
2. [ ] Ajouter reverse proxy dans Caddyfile VPS
3. [ ] Créer sous-domaine DNS OVH
4. [ ] Créer monitor Uptime Kuma VPS
5. [ ] **Mettre à jour ce README**

---

## 🎯 Prochaines Étapes

**Infrastructure** :
- [ ] Backup données Nextcloud → USB 1 TB externe
- [ ] Compte utilisateur Jerome sur Nextcloud
- [ ] Optimiser résolution VM Desktop (1920x1080)
- [ ] Installer environnement Python complet dans VM
- [ ] Configurer sync Nextcloud dans VM

**Personnel** :
- [ ] Bilan mensuel (poids, composition, performance)
- [ ] Bilan sanguin trimestriel

---

## 📁 Structure du Repository

```
claude/
├── configs/
│   ├── caddy/
│   │   ├── Caddyfile (Trigkey)
│   │   └── Caddyfile.vps (VPS OVH)
│   ├── authelia/
│   │   └── configuration.yml
│   ├── fail2ban/
│   │   ├── jail.local
│   │   └── filter.d/
│   ├── crontabs/
│   │   ├── root.txt
│   │   └── frederic.txt
│   └── pihole/
├── scripts/
│   ├── backup-trigkey.sh
│   ├── sync-claude-repo.sh
│   ├── check-vpn-status.sh
│   ├── nextcloud-*.sh
│   └── ...
├── docker-compose/
│   ├── rutorrent.yml
│   ├── uptime-kuma.yml
│   ├── vaultwarden.yml
│   └── ...
├── web/
│   ├── workout/
│   ├── vault/
│   │   └── index.html (portail d'accès)
│   └── fail2ban-stats/
├── vm/
│   └── desktop-vm/ (configs VM VPS)
├── preferences_tech.md
├── preferences_profil.md
└── README.md
```

---

**Dernière mise à jour : 08 décembre 2025**

**Infrastructure Trigkey ✅ Complète et stable**  
**Infrastructure VPS ✅ VM Desktop opérationnelle**  
**Backup + Monitoring redondants ✅**  
**Total : 15+ services auto-hébergés**
