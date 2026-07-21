# UPGRADE-NUC — Fresh install Proxmox 9.1

## Matériel

| Composant | Modèle | Taille | Rôle prévu |
|-----------|--------|--------|------------|
| NVMe | Crucial P3 500 Go | 500 Go | **Disque système** — Proxmox OS + `local-lvm` (LXC/VMs) |
| SSD SATA | SanDisk SSD PLUS 120 Go | 120 Go | **Stockage backup** — `local-backup` (dump, ISO, templates) |

## Version cible

**Proxmox VE 9.1** (même version que le Ryzen, Debian 13 Trixie)

## Layout disque conseillé

### Pendant l'install (sur le NVMe 500 Go)

- **Filesystem :** ext4
- **LVM thin :** Oui (`local-lvm` pour les LXC)
- Sélectionner **uniquement le NVMe** comme disque d'installation
- Ne pas toucher au SSD 120 Go pendant l'install

### Après install — configurer le SSD 120 Go

```bash
# Formater le SSD
mkfs.ext4 /dev/sda

# Monter
mkdir -p /mnt/backup
echo '/dev/sda /mnt/backup ext4 defaults 0 0' >> /etc/fstab
mount -a

# Ajouter comme stockage Proxmox
pvesm add dir local-backup --path /mnt/backup --content backup,vztmpl,iso
```

### Résultat

| Storage | Type | Disque | Taille | Contenu |
|---------|------|--------|--------|---------|
| `local` | dir | NVMe | ~16 Go | ISO, templates |
| `local-lvm` | lvmthin | NVMe | ~460 Go | LXC (disques racine) |
| `local-backup` | dir | SSD 120 Go | ~110 Go | Backups, ISO, templates |

## Post-install

```bash
# Template Debian 12
pveam update
pveam download local debian-12-standard_12.12-1_amd64.tar.zst

# Vérifier l'API
curl -sk https://192.168.1.2:8006

# Installer le template dans local-backup aussi
pveam download local-backup debian-12-standard_12.12-1_amd64.tar.zst
```

## Pourquoi pas ZFS

- 12 Go RAM insuffisants (l'ARC ZFS consomme ~50% de la RAM disponible)
- ext4/LVM-thin déjà éprouvé sur l'infra existante
- Pas de besoin de RAID (un seul disque de données)

## Pourquoi pas LVM fusionné (NVMe + SSD)

- 120 Go en SATA ralentirait le pool
- Si un disque lâche, tout le VG est perdu
- Mieux vaut garder des rôles séparés

## Prochaine étape

Cf. [PLAN-STEP3.md](./PLAN-STEP3.md) pour le reprovisionnement des LXC après upgrade.