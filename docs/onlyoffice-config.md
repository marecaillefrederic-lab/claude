# OnlyOffice Document Server - Configuration

**URL** : https://office.leblais.net  
**Port interne** : 127.0.0.1:8088→80  
**Image Docker** : onlyoffice/documentserver:latest  
**Conteneur** : `onlyoffice`  
**Installé le** : 8 décembre 2025

---

## 🔐 Configuration JWT (CRITIQUE)

OnlyOffice utilise **JWT (JSON Web Token)** pour sécuriser la communication avec Nextcloud.

### JWT Secret actuel

**IMPORTANT** : Ce secret doit être conservé précieusement et **doit être identique** dans :
1. Variables d'environnement du conteneur Docker OnlyOffice
2. Configuration Nextcloud (Paramètres → Administration → OnlyOffice → Clé secrète)

```bash
# Pour récupérer le JWT_SECRET actuel du conteneur
docker inspect onlyoffice | grep JWT_SECRET
```

⚠️ **Si le secret change d'un côté mais pas de l'autre → Erreur "Invalid token"**

---

## 🐳 Commande Docker Complète

### Configuration actuelle (avec JWT activé)

```bash
docker run -d \
  --name onlyoffice \
  --restart always \
  -e JWT_ENABLED=true \
  -e JWT_SECRET="VOTRE_SECRET_ICI" \
  -e JWT_HEADER="Authorization" \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver
```

**Variables d'environnement importantes :**
- `JWT_ENABLED=true` : Active la sécurité JWT
- `JWT_SECRET` : Clé secrète partagée avec Nextcloud
- `JWT_HEADER` : Header HTTP utilisé (standard = "Authorization")

---

## 🔄 Procédure de Recréation du Conteneur

Si vous devez recréer le conteneur (mise à jour, migration, etc.) :

### Étape 1 : Sauvegarder le JWT Secret

```bash
# Récupérer le secret actuel AVANT de supprimer le conteneur
JWT_SECRET=$(docker inspect onlyoffice | grep -oP 'JWT_SECRET=\K[^"]+')
echo "Secret sauvegardé : $JWT_SECRET"

# OU manuellement
docker inspect onlyoffice | grep JWT_SECRET
```

### Étape 2 : Arrêter et supprimer l'ancien conteneur

```bash
docker stop onlyoffice
docker rm onlyoffice
```

### Étape 3 : Recréer avec le MÊME secret

```bash
# Utiliser le secret sauvegardé
docker run -d \
  --name onlyoffice \
  --restart always \
  -e JWT_ENABLED=true \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_HEADER="Authorization" \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver
```

### Étape 4 : Attendre le démarrage (important)

```bash
# OnlyOffice met 30-60 secondes à démarrer
sleep 60

# Vérifier le healthcheck
curl -k https://office.leblais.net/healthcheck
# Doit retourner : true
```

---

## ✅ Vérifications Post-Installation

### 1. Container status

```bash
docker ps | grep onlyoffice
# Doit afficher : ca38746e50c2   onlyoffice/documentserver ... Up X hours
```

### 2. Healthcheck

```bash
curl -k https://office.leblais.net/healthcheck
# Réponse attendue : true
```

### 3. Logs

```bash
# Voir les derniers logs
docker logs --tail 50 onlyoffice

# Suivre les logs en temps réel
docker logs -f onlyoffice
```

### 4. Test depuis Nextcloud

1. Aller dans **Nextcloud** → **Paramètres** → **Administration** → **OnlyOffice**
2. Vérifier que l'adresse est : `https://office.leblais.net/`
3. Cliquer sur **"Enregistrer"**
4. Ouvrir un document test (.docx, .xlsx, .pptx)

---

## 🆘 Troubleshooting

### Erreur "Invalid token" dans Nextcloud

**Symptôme** : Impossible d'ouvrir les documents, message d'erreur "Invalid token"

**Causes possibles :**
1. JWT Secret différent entre OnlyOffice et Nextcloud
2. JWT_ENABLED=false dans OnlyOffice mais secret configuré dans Nextcloud
3. Secret vide dans Nextcloud mais JWT_ENABLED=true dans OnlyOffice

**Solution :**

```bash
# 1. Récupérer le secret actuel du conteneur
docker inspect onlyoffice | grep JWT_SECRET

# 2. Le copier EXACTEMENT dans Nextcloud
#    Paramètres → Administration → OnlyOffice → Clé secrète

# 3. Sauvegarder dans Nextcloud

# 4. Tester en ouvrant un document
```

### Container ne démarre pas

```bash
# Voir les logs d'erreur
docker logs onlyoffice

# Vérifier que le port n'est pas déjà utilisé
netstat -tulpn | grep 8088

# Recréer le conteneur
docker rm -f onlyoffice
# Puis relancer la commande docker run
```

### Avertissement "lecture seule" sur mobile

**Message** : "Sous version gratuite Community, le document est disponible en lecture seule sur mobile"

**Explication :**
- C'est **NORMAL** avec la version Community (gratuite)
- Édition **complète** sur desktop/navigateur web ✅
- Édition **limitée** (lecture seule) sur apps mobiles Nextcloud iOS/Android
- Solution : Utiliser le navigateur mobile ou acheter Enterprise Edition

**Action à prendre :**
- Cliquer sur **"Accepter"**
- Continuer à utiliser normalement sur desktop/web

---

## 🔒 Configuration Caddy (Reverse Proxy)

**Fichier** : `/etc/caddy/Caddyfile`

```caddy
office.leblais.net {
    reverse_proxy localhost:8088
}
```

**Reload après modification :**

```bash
sudo systemctl reload caddy
```

---

## 📋 Configuration Nextcloud

**Paramètres OnlyOffice dans Nextcloud :**

1. **Adresse du ONLYOFFICE Docs** : `https://office.leblais.net/`
2. **Clé secrète** : [Copier le JWT_SECRET du conteneur]
3. **Désactiver la vérification du certificat** : ❌ Décoché (SSL valide via Caddy)

**Pour accéder aux paramètres :**
- Nextcloud → Roue dentée (en haut à droite)
- Administration → OnlyOffice (dans le menu de gauche)

---

## 🔧 Maintenance

### Mise à jour OnlyOffice

```bash
# 1. Sauvegarder le JWT Secret
JWT_SECRET=$(docker inspect onlyoffice | grep -oP 'JWT_SECRET=\K[^"]+')

# 2. Arrêter et supprimer l'ancien conteneur
docker stop onlyoffice
docker rm onlyoffice

# 3. Pull la dernière image
docker pull onlyoffice/documentserver:latest

# 4. Recréer avec le secret sauvegardé
docker run -d \
  --name onlyoffice \
  --restart always \
  -e JWT_ENABLED=true \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_HEADER="Authorization" \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver

# 5. Attendre et vérifier
sleep 60
curl -k https://office.leblais.net/healthcheck
```

### Backup Configuration

Le JWT Secret est automatiquement sauvegardé dans le script `/usr/local/bin/backup-trigkey.sh` via l'inspection des conteneurs Docker.

**Pour backup manuel :**

```bash
# Sauvegarder le secret dans un fichier sécurisé
docker inspect onlyoffice | grep JWT_SECRET > /root/onlyoffice-jwt-backup.txt
chmod 600 /root/onlyoffice-jwt-backup.txt
```

---

## 📊 Ressources

### Utilisation mémoire

OnlyOffice Document Server utilise environ **600-800 MB de RAM** au repos.

```bash
# Voir l'utilisation
docker stats onlyoffice --no-stream
```

### Stockage

Les données temporaires d'OnlyOffice sont stockées dans le conteneur (effacées au redémarrage).

---

## 📚 Liens Utiles

- **Documentation officielle** : https://helpcenter.onlyoffice.com/installation/docs-community-install-docker.aspx
- **Configuration JWT** : https://api.onlyoffice.com/editors/signature/
- **Intégration Nextcloud** : https://github.com/ONLYOFFICE/onlyoffice-nextcloud

---

## ✅ Checklist Installation

Pour référence future, voici les étapes d'installation d'OnlyOffice :

1. [ ] Lancer le conteneur Docker avec JWT_ENABLED=true
2. [ ] Attendre 60 secondes le démarrage complet
3. [ ] Vérifier healthcheck : `curl -k https://office.leblais.net/healthcheck`
4. [ ] Ajouter reverse proxy dans Caddyfile
5. [ ] Créer sous-domaine DNS : office.leblais.net → IP Trigkey
6. [ ] Installer app OnlyOffice dans Nextcloud
7. [ ] Configurer URL + JWT Secret dans Nextcloud
8. [ ] Tester ouverture d'un document
9. [ ] Ajouter monitor Uptime Kuma (local + VPS)
10. [ ] Documenter dans ce fichier

---

## 🎯 Résumé Rapide

**Pour recréer OnlyOffice sans perdre la connexion Nextcloud :**

```bash
# Tout-en-un
JWT_SECRET=$(docker inspect onlyoffice | grep -oP 'JWT_SECRET=\K[^"]+') && \
docker stop onlyoffice && \
docker rm onlyoffice && \
docker run -d --name onlyoffice --restart always \
  -e JWT_ENABLED=true \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_HEADER="Authorization" \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver && \
sleep 60 && \
curl -k https://office.leblais.net/healthcheck
```

---

**Dernière mise à jour** : 8 décembre 2025  
**Statut** : ✅ Opérationnel avec JWT activé
