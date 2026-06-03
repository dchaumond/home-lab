#!/bin/bash
LXC_ID=$1
CONF="/etc/pve/lxc/${LXC_ID}.conf"

# Détection des IDs
KFD_ID=$(ls -l /dev/kfd | awk '{print $5 $6}' | sed 's/,/:/')
DRI_ID=$(ls -l /dev/dri/renderD128 | awk '{print $5 $6}' | sed 's/,/:/')

# Nettoyage et Injection
sed -i '/lxc.cgroup2.devices.allow/d;/lxc.mount.entry: \/dev\/kfd/d;/lxc.mount.entry: \/dev\/dri/d' $CONF

echo "lxc.cgroup2.devices.allow: c $KFD_ID rwm" >> $CONF
echo "lxc.cgroup2.devices.allow: c $DRI_ID rwm" >> $CONF
echo "lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file" >> $CONF
echo "lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir" >> $CONF
echo "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file" >> $CONF

pct reboot $LXC_ID