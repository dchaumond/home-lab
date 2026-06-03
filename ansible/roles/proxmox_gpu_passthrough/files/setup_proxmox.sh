#!/bin/bash
set -e  # Arrête le script en cas d'erreur

LXC_ID=$1
CONF="/etc/pve/lxc/${LXC_ID}.conf"

# Vérification des arguments
if [ -z "$LXC_ID" ]; then
  echo "Usage: $0 <LXC_ID>"
  exit 1
fi

# Vérification de l'existence du conteneur
if [ ! -f "$CONF" ]; then
  echo "Erreur : Configuration du conteneur $LXC_ID introuvable."
  exit 1
fi

# Vérification des périphériques GPU
if [ ! -e "/dev/kfd" ] || [ ! -e "/dev/dri/renderD128" ]; then
  echo "Erreur : Périphériques GPU non trouvés. Vérifiez que le GPU est passé en mode VFIO."
  exit 1
fi

# Détection des IDs
KFD_ID=$(ls -l /dev/kfd | awk '{print $5 $6}' | sed 's/,/:/')
DRI_ID=$(ls -l /dev/dri/renderD128 | awk '{print $5 $6}' | sed 's/,/:/')

# Nettoyage des anciennes règles
sed -i '/lxc.cgroup2.devices.allow/d;/lxc.mount.entry: \/dev\/kfd/d;/lxc.mount.entry: \/dev\/dri/d' "$CONF"

# Injection des nouvelles règles (si non présentes)
if ! grep -q "lxc.cgroup2.devices.allow: c $KFD_ID rwm" "$CONF"; then
  echo "lxc.cgroup2.devices.allow: c $KFD_ID rwm" >> "$CONF"
fi
if ! grep -q "lxc.cgroup2.devices.allow: c $DRI_ID rwm" "$CONF"; then
  echo "lxc.cgroup2.devices.allow: c $DRI_ID rwm" >> "$CONF"
fi

# Montage des périphériques
if ! grep -q "lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file" "$CONF"; then
  echo "lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file" >> "$CONF"
fi
if ! grep -q "lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir" "$CONF"; then
  echo "lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir" >> "$CONF"
fi
if ! grep -q "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file" "$CONF"; then
  echo "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file" >> "$CONF"
fi

# Redémarrage du conteneur
pct reboot "$LXC_ID"
echo "Configuration GPU appliquée au conteneur $LXC_ID. Redémarrage en cours..."