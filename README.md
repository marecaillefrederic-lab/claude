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
- 📡 **Monitoring** : Uptime Kuma local + externe (VPS)

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

**Services actifs (12+)** :
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

### VPS OVH (Backup + Monitoring externe)

**Caractéristiques** :
- **Offre** : VPS-1 (4,58€/mois)
- **RAM** : 8 GB
- **Stockage** : 75 GB SSD
- **IP** : 151.80.59.35

**Rôle** :
- Réception backups quotidiens du Trigkey
- Uptime Kuma externe (monitoring depuis l'extérieur)
- Alertes SMS si Trigkey down

---

## 🔒 Sécurité

- SSL partout (Caddy + Let's Encrypt DNS challenge OVH)
- Fail2ban (13 jails actives)
- Backups quotidiens vers VPS OVH
- Sync configs vers GitHub
- Score Nextcloud : Rating A

---

## 📊 Statistiques

| Métrique | Valeur |
|----------|--------|
| Services auto-hébergés | 12+ |
| Sous-domaines actifs | 15 |
| Jails Fail2ban | 13 |
| Monitors Uptime Kuma | 15+ |
| RAM utilisée | ~4 GB / 16 GB |
| Stockage Nextcloud | ~290 GB / 1 TB |
| Backup quotidien | ✅ Trigkey → VPS |
| Uptime moyen | 99.9% |

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

1. [ ] Installer et configurer le service
2. [ ] Ajouter reverse proxy dans Caddyfile
3. [ ] Créer sous-domaine DNS OVH
4. [ ] Ajouter log JSON pour Fail2ban
5. [ ] Créer filtre + jail Fail2ban
6. [ ] Ajouter au script backup-trigkey.sh
7. [ ] Créer monitor Uptime Kuma
8. [ ] **Lancer sync-claude-repo.sh**

---

## 🎯 Prochaines Étapes

**Infrastructure** :
- [ ] Backup données Nextcloud → USB 1 TB externe
- [ ] Compte utilisateur Jerome sur Nextcloud

**Personnel** :
- [ ] Bilan mensuel (poids, composition, performance)
- [ ] Bilan sanguin trimestriel

---

## 📁 Structure du Repository

```
claude/
├── configs/
│   ├── caddy/
│   │   └── Caddyfile
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
│   └── fail2ban-stats/
├── preferences_tech.md
├── preferences_profil.md
└── README.md
```

---

**Dernière mise à jour : 05 décembre 2025**

**Migration VM Freebox → Trigkey : ✅ Complète**  
**Infrastructure stable et opérationnelle ✅**  
**Backup + Monitoring redondants ✅**
