# Infrastructure leblais.net - Documentation Complète

**Repository GitHub privé** : https://github.com/marecaillefrederic-lab/claude

Documentation complète de l'infrastructure auto-hébergée + profil personnel pour utilisation avec Claude AI.

---

## 📚 Structure du Repository

### 📄 `preferences_tech.md`
**Infrastructure technique complète**

Documentation de tous les services auto-hébergés sur VM Debian 12 (Freebox Server Ultra) :
- 🌐 **Nextcloud** : Cloud familial souverain (290 GB, 3 utilisateurs)
- 🐳 **Docker Services** : Vaultwarden, Uptime Kuma, Linkding, Actual Budget
- 🔒 **Sécurité** : Caddy, Fail2ban, Authelia, WireGuard VPN
- 🌍 **Services Web** : Pi-hole, Terminal Web, Workout Tracker, Dashboard Fail2ban
- 🔄 **Torrents + VPN** : ruTorrent + rtorrent avec ProtonVPN (kill switch)
- 💾 **Backups** : Automatiques quotidiens (local + Google Drive chiffré E2EE)
- ⚙️ **Configuration système** : Optimisations 2 GB RAM, crontab, scripts maintenance

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
- 🍽️ **Nutrition** : Protocole ADF (jeûne alterné), protéines + créatine
- 📊 **Objectifs** : Stabilisation 82-85 kg, préservation masse musculaire
- ⚠️ **Points d'attention** : Surveillance performance, récupération, composition corporelle
- 🎯 **Recommandations** : Santé long terme, métabolisme à 46 ans

**Utilisation avec Claude** :
- Conseils nutrition personnalisés
- Recommandations fitness adaptées
- Suivi progression et ajustements
- Alertes santé si protocole inadapté

---

## 🎯 Objectif du Repository

**Permettre à Claude AI d'avoir un contexte complet** pour :

### Sur l'infrastructure technique
- ✅ Comprendre l'architecture complète
- ✅ Proposer des solutions adaptées à la configuration (2 GB RAM, ARM64)
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

**Hébergement** : VM Debian 12 ARM64 sur Freebox Server Ultra  
**RAM** : 2 GB (optimisée, 500-800 MB disponibles)  
**Stockage VM** : 32 GB  
**Stockage externe** : 1 TB SMB (Freebox)  

**Services actifs (15+)** :
- Nextcloud (cloud familial 290 GB)
- Vaultwarden (passwords)
- Uptime Kuma (monitoring 24/7)
- Pi-hole (blocage pub DNS)
- Linkding (bookmarks)
- Actual Budget (finances)
- ruTorrent + ProtonVPN (torrents sécurisés)
- Authelia (SSO)
- Terminal Web (ttyd)
- Workout Tracker (fitness PPL)
- Dashboard Fail2ban (sécurité)
- WireGuard VPN (accès distant)

**Sécurité** :
- SSL partout (Caddy + Let's Encrypt)
- Fail2ban (13 jails actives)
- Backups quotidiens chiffrés E2EE
- Score SSL Labs : A+

**Monitoring** :
- Uptime Kuma : 15+ monitors
- Disponibilité : 99.9%
- Alertes automatiques

---

## 📊 Statistiques

**Infrastructure** :
- Services auto-hébergés : 15+
- Domaines actifs : 15+ sous-domaines leblais.net
- RAM utilisée : ~1.1 GB / 2 GB (55%)
- Stockage Nextcloud : ~240 GB / 1 TB
- Jails Fail2ban : 13
- Monitors Uptime Kuma : 15+
- Backup quotidien : ✅ Local + Cloud chiffré
- Uptime moyen : 99.9%

**Personnel** :
- Âge : 46 ans
- Entraînements : 5x/semaine (PPL)
- Protocole nutrition : ADF (jeûne alterné)
- Objectif : 82-85 kg (actuellement 90 kg)

---

## 🚀 Utilisation avec Claude

### Chargement du contexte

**Dans un projet Claude** :
1. Ajouter ce repository GitHub
2. Claude charge automatiquement les 2 fichiers preferences
3. Contexte complet disponible pour toutes les conversations

**Alternativement** :
- Mentionner "selon mes preferences tech" → Claude utilise infrastructure
- Mentionner "selon mon profil" → Claude utilise données personnelles

### Exemples de conversations

**Technique** :
- "Comment optimiser encore la RAM Nextcloud ?"
- "Ajouter un service Docker pour XYZ"
- "Troubleshooting : le cron Nextcloud ne tourne plus"
- "Créer un script de maintenance pour le service ABC"

**Personnel** :
- "Devrais-je ajuster mon protocole ADF vu ma baisse de force ?"
- "Recommandations nutrition pour optimiser récupération"
- "Mon poids stagne, que faire ?"
- "Adapter entraînement si fatigue chronique"

---

## 📝 Maintenance

**Mise à jour recommandée** :
- **preferences_tech.md** : Après chaque ajout/modification service
- **preferences_profil.md** : Mensuellement (poids, objectifs, ajustements)
- **README.md** : Si changement structure

**Versioning** :
- Chaque fichier indique "Dernière mise à jour" en haut
- Commits GitHub avec messages descriptifs
- Historique complet via Git

---

## 🔒 Sécurité & Confidentialité

**Repository privé** ✅  
**Pas de secrets** : Aucun mot de passe, token, ou clé API dans les fichiers  
**Données personnelles** : Limitées au strict nécessaire pour conseils pertinents  
**Utilisation Claude** : Données restent dans le contexte Claude (chiffrement Anthropic)

**⚠️ Important** : Ne JAMAIS commit de fichiers contenant :
- Mots de passe
- Tokens API
- Clés privées
- Credentials
- Informations bancaires

---

## 🎓 Leçons Apprises

**Infrastructure** :
- 2 GB RAM suffisants pour 15+ services si optimisé
- Chiffrement E2EE backups = Tranquillité
- Monitoring 24/7 = Détection précoce problèmes
- ARM64 compatible si attention aux binaires
- PostgreSQL + Redis > MySQL pour Nextcloud

**Personnel** :
- Consistance > Perfection
- Écoute du corps > Plan rigide
- Patience avec résultats long terme
- Préservation masse musculaire crucial à 46 ans
- Adaptation protocole selon signaux corps

---

## 📞 Contact

**Infrastructure** : leblais.net  
**Services** : Tous sur sous-domaines leblais.net  
**Monitoring** : https://uptime.leblais.net  

---

## ✅ Checklist Ajout Service

Quand j'ajoute un nouveau service :

1. [ ] Installer et configurer le service
2. [ ] Ajouter reverse proxy Caddy
3. [ ] Créer sous-domaine DNS OVH
4. [ ] Configurer SSL (automatique via Caddy)
5. [ ] Ajouter jail Fail2ban si authentification
6. [ ] Ajouter au script backup-vm.sh
7. [ ] Créer monitor Uptime Kuma
8. [ ] **Mettre à jour preferences_tech.md**
9. [ ] Commit GitHub avec description

---

## 🎯 Prochaines Étapes

**Infrastructure** :
- [ ] DD externe 1 TB → Backup local (remplacer Google Drive)
- [ ] Compte utilisateur Jerome sur Nextcloud
- [ ] Client desktop Nextcloud sur PC famille
- [ ] Évaluer OnlyOffice sur VPS (si besoin édition collaborative)

**Personnel** :
- [ ] Bilan mensuel (poids, composition, performance)
- [ ] Ajuster protocole ADF selon résultats
- [ ] Bilan sanguin trimestriel
- [ ] Optimiser timing nutrition/entraînement

---

**Dernière mise à jour README : 15 novembre 2025**

**Infrastructure stable et optimisée ✅**  
**Documentation complète et à jour ✅**  
**Prêt pour utilisation avec Claude AI ✅**
