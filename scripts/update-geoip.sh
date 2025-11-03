#!/bin/bash
# Script de mise à jour des bases GeoIP2

GEOIP_DIR="/usr/share/GeoIP"
TMP_DIR="/tmp/geoip-update"

echo "🌍 Mise à jour des bases GeoIP2..."

# Créer répertoire temporaire
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# Télécharger les nouvelles bases
wget -q "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb" -O GeoLite2-Country.mmdb
wget -q "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb" -O GeoLite2-City.mmdb

# Vérifier que les fichiers ont été téléchargés
if [ -f "GeoLite2-Country.mmdb" ] && [ -f "GeoLite2-City.mmdb" ]; then
    # Déplacer les nouvelles bases
    sudo mv GeoLite2-Country.mmdb "$GEOIP_DIR/"
    sudo mv GeoLite2-City.mmdb "$GEOIP_DIR/"
    echo "✅ Bases GeoIP2 mises à jour"
else
    echo "❌ Erreur lors du téléchargement"
    exit 1
fi

# Nettoyer
rm -rf "$TMP_DIR"
