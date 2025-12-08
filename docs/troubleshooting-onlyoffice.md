# Résolution Problème OnlyOffice "Invalid Token" - 8 décembre 2025

## 🐛 Problème Initial

**Symptôme** : Erreur "Invalid token" lors de la connexion entre Nextcloud et OnlyOffice Document Server.

**Message d'erreur exact** :
```
Erreur durant la tentative de connexion (Error occurred in the document service: Invalid token)
```

## 🔍 Diagnostic

### État initial du conteneur

```bash
docker ps | grep onlyoffice
# ca38746e50c2   onlyoffice/documentserver   Up 6 days   127.0.0.1:8088->80/tcp

docker logs onlyoffice | grep -i jwt
# Aucune ligne JWT = OnlyOffice avait généré un JWT aléatoire par défaut
```

### Configuration Nextcloud

- **URL OnlyOffice** : `https://office.leblais.net/`
- **Clé secrète** : Vide ou différente du JWT du conteneur
- **Résultat** : Incompatibilité → "Invalid token"

## ✅ Solution Appliquée

### Étape 1 : Test sans JWT (validation)

```bash
# Arrêter et supprimer le conteneur existant
docker stop onlyoffice
docker rm onlyoffice

# Recréer SANS JWT pour tester
docker run -d \
  --name onlyoffice \
  --restart always \
  -e JWT_ENABLED=false \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver

# Attendre le démarrage
sleep 60

# Vérifier
curl -k https://office.leblais.net/healthcheck
# Retour : true ✅
```

**Dans Nextcloud** :
- Cocher "Désactiver la vérification du certificat"
- Laisser "Clé secrète" vide
- Sauvegarder

**Résultat** : ✅ Connexion fonctionnelle, document s'ouvre

### Étape 2 : Activation JWT (sécurité)

```bash
# Générer un secret fort
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT Secret : $JWT_SECRET"

# Arrêter le conteneur test
docker stop onlyoffice
docker rm onlyoffice

# Recréer AVEC JWT sécurisé
docker run -d \
  --name onlyoffice \
  --restart always \
  -e JWT_ENABLED=true \
  -e JWT_SECRET="$JWT_SECRET" \
  -e JWT_HEADER="Authorization" \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver

# Attendre le démarrage
sleep 60

# Vérifier
docker logs onlyoffice | grep -i jwt
# Pas de lignes JWT = normal, c'est OK ✅
```

**Dans Nextcloud** :
- Décocher "Désactiver la vérification du certificat"
- Copier EXACTEMENT le `$JWT_SECRET` dans "Clé secrète"
- Sauvegarder

**Résultat** : ✅ Connexion sécurisée fonctionnelle

## 📋 Configuration Finale

### Commande Docker complète

```bash
docker run -d \
  --name onlyoffice \
  --restart always \
  -e JWT_ENABLED=true \
  -e JWT_SECRET="VotreSecretIci123ABC==" \
  -e JWT_HEADER="Authorization" \
  -p 127.0.0.1:8088:80 \
  onlyoffice/documentserver
```

### Configuration Caddy

```caddy
office.leblais.net {
    reverse_proxy localhost:8088
}
```

### Configuration Nextcloud

- **Adresse OnlyOffice** : `https://office.leblais.net/`
- **Clé secrète** : [Identique au JWT_SECRET du conteneur]
- **Vérification certificat** : Activée ✅

## 🎯 Leçons Apprises

### Pourquoi ce problème ?

1. **OnlyOffice récent** : Active JWT par défaut avec un secret aléatoire
2. **Installation basique** : Sans spécifier JWT_SECRET → secret généré automatiquement
3. **Nextcloud** : Configuré sans le secret → incompatibilité

### Comment éviter ce problème ?

1. ✅ **Toujours spécifier JWT_SECRET** lors de la création du conteneur
2. ✅ **Documenter le secret** dans un fichier sécurisé
3. ✅ **Sauvegarder le secret** avant toute recréation du conteneur
4. ✅ **Vérifier la correspondance** Nextcloud ↔ OnlyOffice

### Commande de récupération du secret

```bash
# Pour récupérer le JWT_SECRET d'un conteneur existant
docker inspect onlyoffice | grep JWT_SECRET

# Ou en variable
JWT_SECRET=$(docker inspect onlyoffice | grep -oP 'JWT_SECRET=\K[^"]+')
echo $JWT_SECRET
```

## ⚠️ Point d'Attention

### Message "lecture seule sur mobile"

**Message affiché** :
> "Sous version gratuite Community, le document est disponible en lecture seule. Pour accéder aux éditeurs mobiles web, vous avez besoin d'une licence payante."

**Explication** :
- C'est **NORMAL** avec OnlyOffice Community Edition (gratuite)
- **Édition complète** sur desktop/navigateur web ✅
- **Lecture seule** sur apps mobiles Nextcloud (iOS/Android)
- **Solution** : Cliquer sur "Accepter" et continuer normalement

**Pas un bug**, juste une limitation de la version Community.

## 🔄 Procédure de Recréation Future

Si vous devez recréer le conteneur (mise à jour, migration, etc.) :

```bash
# 1. Sauvegarder le JWT_SECRET actuel
JWT_SECRET=$(docker inspect onlyoffice | grep -oP 'JWT_SECRET=\K[^"]+')
echo "Secret sauvegardé : $JWT_SECRET"

# 2. Arrêter et supprimer
docker stop onlyoffice
docker rm onlyoffice

# 3. Pull dernière image (optionnel)
docker pull onlyoffice/documentserver:latest

# 4. Recréer avec LE MÊME secret
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
# Doit retourner : true
```

## 📚 Documentation Créée

Suite à cette résolution, les fichiers suivants ont été créés :

1. **`onlyoffice-config.md`** : Documentation complète OnlyOffice
2. **`troubleshooting-onlyoffice.md`** : Ce fichier (résolution du problème)

Ces fichiers sont à ajouter dans le repository GitHub pour référence future.

## ✅ Checklist Post-Résolution

- [x] OnlyOffice fonctionne avec JWT activé
- [x] Documents s'ouvrent correctement dans Nextcloud
- [x] JWT_SECRET documenté et sauvegardé
- [x] Configuration Caddy validée
- [x] Healthcheck fonctionne : `curl -k https://office.leblais.net/healthcheck`
- [x] Documentation créée et complète
- [ ] À ajouter au script `backup-trigkey.sh` (déjà inclus via inspect Docker)
- [ ] À ajouter aux monitors Uptime Kuma (local + VPS)
- [ ] À sync sur GitHub via `sync-claude-repo.sh`

---

**Date de résolution** : 8 décembre 2025  
**Durée de résolution** : ~30 minutes  
**Statut final** : ✅ Opérationnel et sécurisé avec JWT
