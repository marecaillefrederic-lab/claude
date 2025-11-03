#!/bin/bash

echo "=== Backups disponibles sur Google Drive ==="
rclone ls gdrive:Backups/VM-Debian/

echo ""
read -p "Nom du fichier à restaurer : " filename

if [ -z "$filename" ]; then
    echo "Annulé"
    exit 1
fi

TEMP_FILE="/tmp/$filename"

echo "Téléchargement depuis Google Drive..."
rclone copy "gdrive:Backups/VM-Debian/$filename" /tmp/ -P

if [ $? -eq 0 ]; then
    echo "✓ Téléchargement réussi"
    sudo /usr/local/bin/restore-vm.sh "$TEMP_FILE"
    rm -f "$TEMP_FILE"
else
    echo "✗ Erreur de téléchargement"
    exit 1
fi
