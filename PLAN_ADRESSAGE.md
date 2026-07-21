# PLAN_ADRESSAGE.md

## Plan d'adressage IP pour Home Lab Proxmox

### Contexte
- **Infrastructure** : 2 nœuds Proxmox séparés (`pve` et `pve-ryzen`), pas de cluster.
- **Plage IP** : `192.168.1.0/24` (50 premières IP réservées pour l'infrastructure).
- **Objectif** : Logique d'adressage claire, évolutive et facile à gérer.

---

### Plages IP réservées

| Plage IP          | Usage                     | Règle                                      |
|-------------------|---------------------------|--------------------------------------------|
| **1.1**           | Routeur (ASUS RT-AC86U)   | Fixe.                                      |
| **1.2**           | `pve` (NUC)               | Hostname dans `.env.json`, IP gérée via DHCP routeur + statique Proxmox. |
| **1.3**           | `pve-ryzen`               | Hostname dans `.env.json`, IP gérée via DHCP routeur + statique Proxmox. |
| **1.4 - 1.8**     | VIP                        | 1.4 (Home Assistant `ha.home`), 1.5-1.8 en réserve. |
| **1.9**           | LXC "Data" (Samba/MinIO)   | **Exception** — IP fixe, toujours sur `pve-ryzen` (disque 4T). |
| **1.10 - 1.19**   | LXC "Dev"                  | **Règle ID→IP** : `pve` → `ID - 100`, `pve-ryzen` → `ID - 200`. |
| **1.20 - 1.29**   | LXC "Apps/Runner"          | **Règle ID→IP** : `pve` → `ID - 100`, `pve-ryzen` → `ID - 200`. |
| **1.30 - 1.48**   | Réserve / futurs services  | Libre.                                     |
| **1.49**          | LXC "IA" (ai-node)         | **Exception** — IP fixe, sur `pve-ryzen` (GPU passthrough). |
| **1.21**          | LXC "Home Automation"      | **Exception** — IP fixe, sur `pve-ryzen`, VIP `1.4`. |
| **1.50**          | Réserve globale            | Libre.                                     |

---

### Logique de mapping ID Proxmox → IP

La règle s'applique **uniquement aux LXC de type Dev et Apps/Runner**. Tout le reste est en IP fixe (exceptions).

- **Sur `pve` (NUC)** : `IP = 192.168.1.<ID - 100>`
- **Sur `pve-ryzen`** : `IP = 192.168.1.<ID - 200>`

#### Exemples (règle)

| LXC                 | Hyperviseur | ID Proxmox | IP cible |
|---------------------|-------------|------------|----------|
| dev-station-nuc     | `pve`       | 110        | 1.10     |
| dev-station-ryzen   | `pve-ryzen` | 211        | 1.11     |
| apps-runner-nuc     | `pve`       | 120        | 1.20     |
| apps-runner-ryzen   | `pve-ryzen` | 222        | 1.22     |

#### Exceptions (IP fixes, ne suivent pas la règle)

| LXC                    | Hyperviseur | IP fixe | Raison                                  |
|------------------------|-------------|---------|-----------------------------------------|
| lxc-storage (Data)     | `pve-ryzen` | 1.9     | Disque 4T, service critique.            |
| home-automation-ryzen  | `pve-ryzen` | 1.21    | Service critique, VIP `1.4`.            |
| ai-node                | `pve-ryzen` | 1.49    | GPU passthrough, service dédié.         |

---

### Script de mapping ID → IP

```bash
# Génère l'IP à partir de l'ID Proxmox (pour Dev et Runners uniquement)
get_ip_from_id() {
  local id=$1
  local hypervisor=$2
  if [[ "$hypervisor" == "pve-ryzen" ]]; then
    echo "192.168.1.$((id - 200))"
  else
    echo "192.168.1.$((id - 100))"
  fi
}
```

---

### Renumérotation d'un conteneur LXC

Proxmox ne permet pas de changer un CT ID directement. Procédure standard :

```bash
# 1. Arrêter le conteneur
pct stop <old_id>

# 2. Sauvegarder
vzdump <old_id> --mode stop --compress zstd

# 3. Restaurer avec le nouvel ID
pct restore <new_id> /var/lib/vz/dump/vzdump-lxc-<old_id>-*.tar.zst

# 4. Ajuster l'IP dans le conteneur (via pct ou dans le CT)
pct set <new_id> --net0 name=eth0,bridge=vmbr0,ip=dhcp
# ou directement dans le fichier de config

# 5. Supprimer l'ancien conteneur (après vérification)
pct destroy <old_id>
```

---

### Changer l'IP d'un hyperviseur Proxmox sans perte de connexion SSH

**Problème** : si on modifie l'IP statique dans `/etc/network/interfaces` puis qu'on redémarre le réseau, on perd la connexion SSH.

**Solution** : ajouter la nouvelle IP sans supprimer l'ancienne, tester, puis basculer.

```bash
# 1. Ajouter la nouvelle IP (les 2 IPs coexistent)
ip addr add 192.168.1.3/24 dev vmbr0

# 2. Tester SSH sur la nouvelle IP
ssh root@192.168.1.3
# Si OK → continuer. Sinon, on est toujours connecté sur l'ancienne IP.

# 3. Mettre à jour la configuration permanente
#    Modifier /etc/network/interfaces avec la nouvelle adresse
#    (ne pas redémarrer le réseau tout de suite)

# 4. Mettre à jour la réservation DHCP sur le routeur
#    Interface ASUS > LAN > DHCP Server > Manual Assignment

# 5. Supprimer l'ancienne IP (quand tout est confirmé)
ip addr del 192.168.1.20/24 dev vmbr0

# 6. Vérifier que le hostname pve-ryzen se résout vers la nouvelle IP
#    Terraform utilise le hostname, donc pas de changement nécessaire côté IaC.
```

---

### Plan de migration (résumé)

1. **Hyperviseurs** : IPs déjà gérées via hostname, seuls les DHCP/router sont à adapter.
2. **LXC Data** : IP `1.9`, aucune renumérotation nécessaire (exception).
3. **LXC Dev et Runners** : renuméroter les CT pour appliquer la règle ID→IP.
4. **LXC Home Automation et IA** : IPs fixes, pas de changement.
5. **VIP** : `1.4` pour Home Assistant (à configurer avec `keepalived`).
6. **`.env.json`** : mettre à jour les IPs, Terraform ne nécessite pas de modification (utilise déjà les variables).
