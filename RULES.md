# RULES.md - Règles de Codage et Bonnes Pratiques

Ce document décrit les règles de codage et bonnes pratiques à suivre pour les configurations **Terraform** et **Ansible** dans ce projet.

---

## **📂 Structure du Projet**

### **1.1. Arborescence**
```
/home/dch/projects/home-lab/
├── ansible/
│   ├── inventory/
│   │   └── hosts.yml          # Fichier d'inventaire principal
│   ├── roles/
│   │   └── dev_station/
│   │       ├── tasks/
│   │       │   ├── main.yml      # Inclut les fichiers de tâches (DOIT contenir les tags)
│   │       │   ├── dev.yml       # Tâches de développement
│   │       │   └── rdp.yml       # Tâches RDP (XFCE + XRDP - DOIT être tagué)
│   │       └── ...
│   ├── site-ryzen.yml        # Playbook principal pour les machines Ryzen
│   └── site-nuc.yml          # Playbook principal pour les machines NUC
├── .env.json                  # Fichier de variables sensibles (NE JAMAIS COMMITTER)
├── RULES.md                   # Ce fichier
└── AGENTS.md                  # Documentation des agents et workflows
```

### **1.2. Règles Strictes**
- **Variables sensibles** : Toujours utiliser `.env.json` pour les mots de passe, IPs, et utilisateurs.
  Exemple : `{{ secrets.user.name }}` pour l'utilisateur cible.
- **Tags Ansible** :
  - **Ne taguez que les blocs qui ont un sens en isolation** (ex: `rdp`, `desktop`, `user`).
  - Un bloc non tagué s'exécute toujours (`--tags` ne filtre que les tâches taguées).
- **Exécution** : Toujours tester en mode `--check` avant d'appliquer les changements.

---

## **📌 Terraform**

### **1. Structure des fichiers**
- **Modules** :
  - Chaque module doit contenir :
    - `main.tf` : Définition des ressources.
    - `variables.tf` : Déclaration des variables avec **types**, **valeurs par défaut** et **descriptions**.
    - `outputs.tf` : Déclaration des sorties du module.
    - `versions.tf` (optionnel) : Contraintes de version pour les providers.

- **Environnements** :
  - Séparer les configurations par environnement (ex: `environments/ryzen/`, `environments/nuc/`).
  - Utiliser des fichiers dédiés pour chaque composant (ex: `apps_runner.tf`, `ai.tf`).


### **2. Conventions de nommage**
- **Ressources** :
  - Utiliser un préfixe `this` pour les ressources principales dans les modules (ex: `proxmox_virtual_environment_container.this`).
  - Nommage explicite pour les variables (ex: `cpu_cores`, `memory_size`, `disk_datastore_id`).

- **Variables** :
  - Préfixer les variables par leur domaine (ex: `cpu_`, `memory_`, `disk_`).
  - Utiliser des noms en **snake_case** (ex: `vm_id`, `os_type`).

### **3. Bonnes pratiques**

#### **Ansible**
##### **1. Configuration**
- **Inventaire** :
  - Le groupe `lxc_devstation_ryzen` cible `dev-station-ryzen` avec `ansible_user: root`.
  - Variables sensibles dans `.env.json` (ex: `secrets.user.name = "dch"`).

- **Playbooks** :
  - `site-ryzen.yml` inclut le rôle `dev_station` pour `lxc_devstation_ryzen`.
  - **Problème courant** : Les tâches RDP ne s'exécutent **pas** avec `--tags rdp` si l'inclusion dans `main.yml` n'est pas taguée.

##### **2. Tâches RDP (`rdp.yml`)**
- **Paquets à installer** : `xfce4`, `xrdp`, `xorg`, `dbus-x11`.
- **Fichier `.xsession`** : Doit être dans `/home/{{ secrets.user.name }}/.xsession` (pas `/root/`).
- **Redémarrage** : Forcer avec `systemd` (ex: `state: restarted`).

##### **3. Commandes Clés**
- **Exécution complète** (sans tag) :
  ```bash
  ansible-playbook -i ansible/inventory/hosts.yml ansible/site-ryzen.yml --limit lxc_devstation_ryzen
  ```

- **Diagnostic** (mode lecture seule) :
  ```bash
  ansible-playbook -i ansible/inventory/hosts.yml ansible/site-ryzen.yml --limit lxc_devstation_ryzen --check --diff -vvv
  ```

- **Exécution avec tags** (après vérification) :
  ```bash
  ansible-playbook -i ansible/inventory/hosts.yml ansible/site-ryzen.yml --limit lxc_devstation_ryzen --tags rdp
  ```

##### **4. Vérifications Post-Exécution**
- **Sur la machine cible** (`dev-station-ryzen`) :
  ```bash
  dpkg -l | grep -E "xrdp|xfce4"          # Paquets installés
  systemctl status xrdp                 # Statut du service
  cat /home/dch/.xsession               # Contenu du fichier .xsession
  groups dch                            # Groupes de l'utilisateur
  ```

- **Depuis un client RDP** : Se connecter à l'IP de `dev-station-ryzen` (ex: `192.168.1.11`).

##### **5. Dépannage**
| Problème                          | Solution                                                                                     |
|-----------------------------------|----------------------------------------------------------------------------------------------|
| Tâches RDP ignorées               | Ajouter `tags: rdp` à l'inclusion dans `main.yml`.                                           |
| Paquets non installés             | Utiliser `state: latest` + `update_cache: yes` dans `rdp.yml`.                               |
| Fichier `.xsession` mal placé     | Vérifier le chemin `/home/{{ secrets.user.name }}/.xsession`.                               |
| Service XRDP non démarré          | Forcer le redémarrage avec `state: restarted` dans `rdp.yml`.                               |


#### **Sécurité**
- Marquer les variables sensibles avec `sensitive = true` :
  ```hcl
  variable "root_password" {
    description = "Mot de passe root du conteneur"
    type        = string
    sensitive   = true
  }
  ```

- Charger les secrets depuis un fichier externe (ex: `.env.json`) :
  ```hcl
  locals {
    secrets = jsondecode(file("${path.module}/../../../.env.json"))
  }
  ```


#### **Validation**
- Ajouter des règles de validation pour les variables critiques :
  ```hcl
  variable "os_type" {
    description = "Type d'OS (lxc ou ubuntu)"
    type        = string
    validation {
      condition     = contains(["lxc", "ubuntu"], var.os_type)
      error_message = "Le type d'OS doit être 'lxc' ou 'ubuntu'."
    }
  }
  ```


#### **Modularité**
- Utiliser `dynamic` pour les blocs répétitifs :
  ```hcl
  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name   = network_interface.value.name
      bridge = network_interface.value.bridge
    }
  }
  ```

- Centraliser les configurations dynamiques avec `locals` :
  ```hcl
  locals {
    default_mount_points = [
      {
        path         = "/mnt/data"
        size         = "10G"
        acl          = true
        backup       = true
        read_only    = false
      }
    ]
  }
  ```


#### **Réseau et Stockage**
- Configurer les interfaces réseau de manière flexible (IPv4/IPv6) :
  ```hcl
  ip_config {
    ipv4 {
      address = "dhcp"
    }
  }
  ```

- Gérer les points de montage avec des options avancées :
  ```hcl
  mount_point {
    path         = "/mnt/data"
    size         = "10G"
    acl          = true
    backup       = true
    read_only    = false
  }
  ```


### **4. Documentation**
- Ajouter des **descriptions** pour toutes les variables et outputs :
  ```hcl
  output "container_id" {
    description = "ID du conteneur LXC créé"
    value       = proxmox_virtual_environment_container.this.id
  }
  ```

- Commenter les sections complexes :
  ```hcl
  # =============================================
  # Configuration CPU et Mémoire
  # =============================================
  cpu {
    cores = var.cpu_cores
  }
  memory {
    dedicated = var.memory_size
  }
  ```


---

## **📌 Ansible**

### **1. Structure des fichiers**
- **Rôles** :
  - Chaque rôle doit contenir :
    - `tasks/main.yml` : Tâches principales.
    - `handlers/main.yml` : Handlers pour redémarrer les services.
    - `defaults/main.yml` : Variables par défaut.
    - `vars/main.yml` : Variables spécifiques au rôle.
    - `files/` : Scripts ou fichiers statiques.
    - `templates/` (optionnel) : Modèles Jinja2.

- **Playbooks** :
  - Utiliser des noms explicites (ex: `site-ryzen.yml`, `site-nuc.yml`).
  - Cibler des groupes spécifiques dans l'inventaire (ex: `hosts: lxc_ai`).


### **2. Conventions de nommage**
- **Rôles et tâches** :
  - Noms de rôles en **snake_case** (ex: `ai`, `apps_runner`, `dev_station`).
  - Noms de tâches descriptifs (ex: `Configurer le GPU Passthrough`).

- **Variables** :
  - Utiliser des noms explicites (ex: `ansible_host`, `docker_admin.user`).
  - Centraliser les secrets dans un fichier `secrets` (ex: `secrets.ansible_host`).


### **3. Bonnes pratiques**
#### **Sécurité**
- Utiliser `no_log: true` pour les tâches sensibles :
  ```yaml
  - name: Définir le mot de passe root
    user:
      name: root
      password: "{{ secrets.root_password | password_hash('sha512') }}"
    no_log: true
  ```

- Charger les secrets depuis un fichier externe (ex: `.env.json`) :
  ```yaml
  vars_files:
    - ../../../.env.json
  ```

#### **Gestion des Conteneurs LXC sur Proxmox 9.1.1**
- **Redémarrage d'un conteneur** :
  - Utiliser `pct stop <vmid>` puis `pct start <vmid>` (la commande `pct restart` n'est pas disponible dans Proxmox 9.1.1).
  - Exemple :
    ```yaml
    - name: Arrêter le conteneur LXC
      ansible.builtin.command: "pct stop {{ secrets.apps_runner_ryzen.ct_id }}"
      delegate_to: "{{ secrets.pve_host_ryzen }}"
      become: true
    
    - name: Démarrer le conteneur LXC
      ansible.builtin.command: "pct start {{ secrets.apps_runner_ryzen.ct_id }}"
      delegate_to: "{{ secrets.pve_host_ryzen }}"
      become: true
    ```

- **Vérification de l'état d'un conteneur** :
  - Utiliser `pct status <vmid>` pour vérifier l'état du conteneur.
  - Exemple :
    ```bash
    ansible pve-ryzen -i ansible/inventory/hosts.yml -a "pct status {{ secrets.apps_runner_ryzen.ct_id }}" -u root --private-key ~/.ssh/id_ed25519_homelab
    ```

- **Vérification des commandes `pct` disponibles** :
  - Utiliser `pct help` pour lister les commandes disponibles.
  - Exemple :
    ```bash
    ansible pve-ryzen -i ansible/inventory/hosts.yml -a "pct help" -u root --private-key ~/.ssh/id_ed25519_homelab
    ```

#### **Mode de Travail**
- **Ne jamais faire de modifications en mode build en cas d'échec sans ma validation** :
  - Propose des modifications, mais attends ma validation avant de les appliquer.
  - Exemple :
    ```yaml
    - name: Proposer une modification
      ansible.builtin.command: "pct stop {{ secrets.apps_runner_ryzen.ct_id }}"
      delegate_to: "{{ secrets.pve_host_ryzen }}"
      become: true
      when: false  # Proposer sans exécuter
    ```

#### **Gestion des Variables**
- **Toutes les variables doivent être gérées dans `.env.json` à la racine du projet** :
  - Aucune variable ne doit être définie en dur dans les fichiers de configuration (Terraform, Ansible, etc.).
  - Exemple de `.env.json` :
    ```json
    {
      "apps_runner_ryzen": {
        "ct_id": 402,
        "ip": "192.168.1.42/24"
      },
      "pve_host_ryzen": "pve-ryzen"
    }
    ```
  - Utiliser `{{ secrets.<variable> }}` pour accéder aux variables dans les fichiers Ansible ou Terraform.

#### **Mode de Travail**
- **Ne jamais faire de modifications en mode build en cas d'échec sans ma validation** :
  - Propose des modifications, mais attends ma validation avant de les appliquer.
  - Exemple :
    ```yaml
    - name: Proposer une modification
      ansible.builtin.command: "pct stop {{ secrets.apps_runner_ryzen.ct_id }}"
      delegate_to: "{{ secrets.pve_host_ryzen }}"
      become: true
      when: false  # Proposer sans exécuter
    ```


#### **Modularité**
- Découper les tâches complexes en sous-fichiers :
  ```yaml
  - include_tasks: dev.yml
  ```

- Utiliser des `blocks` pour regrouper les tâches logiquement :
  ```yaml
  - name: Configurer Docker
    block:
      - name: Ajouter le dépôt Docker
        apt_repository:
          repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable
          state: present
      - name: Installer Docker
        apt:
          name: docker-ce
          state: present
    become: true
  ```


#### **Gestion des services**
- Activer et démarrer les services avec `systemd` :
  ```yaml
  - name: Activer et démarrer Docker
    systemd:
      name: docker
      enabled: true
      state: started
  ```

- Utiliser `notify` pour redémarrer les services si nécessaire :
  ```yaml
  - name: Configurer le daemon Docker
    copy:
      dest: /etc/docker/daemon.json
      content: |
        {
          "log-driver": "json-file",
          "log-opts": {
            "max-size": "10m"
          }
        }
    notify: Redémarrer Docker
  ```


#### **Vérifications et Corrections Automatiques**
- **Vérifications** :
  - Utiliser `register` et `failed_when` pour contrôler les erreurs :
    ```yaml
    - name: Vérifier que Docker fonctionne
      command: docker run --rm hello-world
      register: docker_test
      failed_when: "'Hello from Docker!' not in docker_test.stdout"
    ```

  - Ajouter des vérifications post-installation :
    ```yaml
    - name: Vérifier que ROCm est installé
      command: rocminfo | grep gfx
      register: rocm_test
      changed_when: false
    ```

- **Corrections Automatiques** :
  - En cas d'erreur, **proposer et intégrer un correctif** directement dans les tâches Ansible.
  - Utiliser des tâches conditionnelles pour appliquer les corrections :
    ```yaml
    - name: Corriger l'installation de ROCm si nécessaire
      block:
        - name: Réinstaller ROCm si la vérification échoue
          apt:
            name: rocm-utils
            state: present
          when: rocm_test.failed
      rescue:
        - name: Forcer la réinstallation de ROCm
          command: apt install --reinstall -y rocm-utils
          when: rocm_test.failed
    ```

  - **Exemple complet** : Vérification + Correction pour Docker :
    ```yaml
    - name: Vérifier que Docker fonctionne
      command: docker run --rm hello-world
      register: docker_test
      ignore_errors: true
      changed_when: false

    - name: Réinstaller Docker si la vérification échoue
      block:
        - name: Désinstaller Docker
          apt:
            name: docker-ce
            state: absent
        - name: Réinstaller Docker
          apt:
            name: docker-ce
            state: present
      when: docker_test.failed
    ```


### **4. Documentation**
- Commenter les tâches pour expliquer leur rôle :
  ```yaml
  # Configurer le GPU Passthrough pour les conteneurs LXC
  - name: Ajouter les périphériques GPU au conteneur
    lxc_config:
      name: "{{ inventory_hostname }}"
      config:
        - "lxc.cgroup2.devices.allow = c 226:* rwm"
        - "lxc.mount.entry = /dev/dri dev/dri none bind,optional,create=dir"
  ```

- Utiliser des `tags` pour organiser les tâches :
  ```yaml
  - name: Installer les outils de développement
    apt:
      name: "{{ dev_tools }}"
      state: present
    tags: dev
  ```


---

## **🔄 Bonnes pratiques transverses**

### **1. Gestion des secrets**
- **Centralisation** :
  - Utiliser un fichier `.env.json` pour stocker les secrets (Terraform et Ansible).
  - Exemple de structure :
    ```json
    {
      "proxmox": {
        "api_url": "https://pve.example.com/api2/json",
        "api_token_id": "root@pam!token",
        "api_token_secret": "secret"
      },
      "ansible": {
        "ansible_host": "10.0.0.1",
        "ansible_user": "root",
        "ansible_password": "password"
      }
    }
    ```

- **Sécurité** :
  - Ajouter `.env.json` au `.gitignore`.
  - Utiliser des outils comme `git-secret` ou `sops` pour chiffrer les secrets.


### **2. Structure des répertoires**
| Outil      | Répertoire               | Contenu                                                                                     |
|------------|--------------------------|---------------------------------------------------------------------------------------------|
| Terraform  | `terraform/`             | Configurations Terraform.                                                                   |
|            | `terraform/modules/`     | Modules réutilisables (ex: `lxc`, `vm`).                                                   |
|            | `terraform/environments/`| Configurations par environnement (ex: `ryzen`, `nuc`).                                     |
| Ansible    | `ansible/`               | Configurations Ansible.                                                                     |
|            | `ansible/roles/`         | Rôles réutilisables (ex: `ai`, `apps_runner`).                                              |
|            | `ansible/inventory/`     | Fichiers d'inventaire (ex: `hosts.yml`).                                                    |
|            | `ansible/site-*.yml`     | Playbooks principaux.                                                                       |


### **3. Collaboration**
- **Documentation** :
  - Ajouter un `README.md` dans chaque rôle/module pour expliquer son utilisation.
  - Documenter les variables critiques et leurs valeurs possibles.

- **Validation** :
  - Utiliser des outils de linting :
    - Terraform :
      ```bash
      terraform validate
      tflint
      ```
    - Ansible :
      ```bash
      ansible-lint
      ```
  - Tester les configurations dans des environnements isolés avant déploiement.

---

### **Commandes de Déploiement**
#### **Terraform**
- **Initialisation** (à exécuter une seule fois par environnement) :
  ```bash
  cd /home/dch/projects/home-lab/terraform/environments/<env>  # Ex: ryzen, nuc
  terraform init
  ```

- **Validation** (avant tout déploiement) :
  ```bash
  terraform validate
  tflint
  ```

- **Plan d'exécution** (pour prévisualiser les changements) :
  ```bash
  terraform plan -target=module.<nom_du_module>  # Ex: -target=module.apps_runner_ryzen
  ```

- **Déploiement** (appliquer les changements) :
  ```bash
  terraform apply -target=module.<nom_du_module> -auto-approve
  ```

- **Destruction** (supprimer un conteneur) :
  ```bash
  terraform destroy -target=module.<nom_du_module> -auto-approve
  ```

- **Bonnes pratiques** :
  - Toujours cibler un module spécifique avec `-target` pour éviter les modifications involontaires.
  - Utiliser `-auto-approve` uniquement en environnement de test.

---

#### **Ansible**
- **Vérification de syntaxe** (avant tout déploiement) :
  ```bash
  ansible-playbook -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml /home/dch/projects/home-lab/ansible/site-<env>.yml --syntax-check  # Ex: site-ryzen.yml
  ```

- **Déploiement ciblé** (pour un groupe spécifique) :
  ```bash
  ansible-playbook -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml /home/dch/projects/home-lab/ansible/site-<env>.yml --limit <groupe>  # Ex: --limit lxc_apps_runner_ryzen
  ```

- **Déploiement avec tags** (pour exécuter des tâches spécifiques) :
  ```bash
  ansible-playbook -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml /home/dch/projects/home-lab/ansible/site-<env>.yml --limit <groupe> --tags <tag>  # Ex: --tags docker
  ```

- **Vérifications post-déploiement** :
  - **Accès SSH** :
    ```bash
    ansible <groupe> -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml -m ping
    ```
  - **Docker** :
    ```bash
    ansible <groupe> -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml -a "docker --version"
    ansible <groupe> -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml -a "docker info"
    ```
  - **Test Docker** :
    ```bash
    ansible <groupe> -i /home/dch/projects/home-lab/ansible/inventory/hosts.yml -a "docker run --rm busybox echo 'Docker fonctionne !'"
    ```

- **Bonnes pratiques** :
  - Toujours utiliser `--limit` pour cibler un groupe spécifique.
  - Vérifier la syntaxe avec `--syntax-check` avant tout déploiement.
  - Utiliser `--tags` pour exécuter des tâches spécifiques (ex: `docker`, `lxc`).


### **4. Automatisation**
- **CI/CD** :
  - Intégrer des pipelines pour valider les configurations (ex: GitHub Actions, GitLab CI).
  - Exemple de pipeline pour Terraform :
    ```yaml
    jobs:
      validate:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - uses: hashicorp/setup-terraform@v2
          - run: terraform init
          - run: terraform validate
    ```

  - Exemple de pipeline pour Ansible (incluant des vérifications et corrections) :
    ```yaml
    jobs:
      test:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - name: Installer Ansible
            run: pip install ansible
          - name: Exécuter le playbook avec vérifications
            run: ansible-playbook site-ryzen.yml --tags "verify,fix"
    ```

- **Tests** :
  - Utiliser des outils comme `kitchen-terraform` pour tester les modules Terraform.
  - Utiliser `molecule` pour tester les rôles Ansible **avec des scénarios de correction automatique** :
    ```yaml
    # molecule/default/converge.yml
    - name: Converge
      hosts: all
      tasks:
        - name: Inclure le rôle avec vérifications et corrections
          include_role:
            name: ai
          tags: verify,fix
    ```

- **Corrections Automatiques dans les Tests** :
  - Dans les tests Ansible (ex: `molecule`), intégrer des tâches pour **détecter et corriger les erreurs** automatiquement.
  - Exemple de scénario Molecule avec correction :
    ```yaml
    # molecule/default/verify.yml
    - name: Vérifier et corriger l'installation de Docker
      hosts: all
      tasks:
        - name: Vérifier que Docker fonctionne
          command: docker run --rm hello-world
          register: docker_test
          ignore_errors: true
          changed_when: false

        - name: Réinstaller Docker si nécessaire
          block:
            - name: Désinstaller Docker
              apt:
                name: docker-ce
                state: absent
            - name: Réinstaller Docker
              apt:
                name: docker-ce
                state: present
          when: docker_test.failed
    ```


---

## **📂 Exemple de structure finale**
```
home-lab/
├── .env.json                  # Secrets (ignoré par Git)
├── .gitignore
├── RULES.md                   # Ce fichier
├── terraform/
│   ├── modules/
│   │   ├── lxc/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   ├── environments/
│   │   ├── ryzen/
│   │   │   ├── apps_runner.tf
│   │   │   ├── ai.tf
│   │   │   └── provider.tf
│   └── README.md
├── ansible/
│   ├── roles/
│   │   ├── ai/
│   │   │   ├── tasks/
│   │   │   │   ├── main.yml
│   │   │   │   └── gpu.yml
│   │   │   ├── handlers/
│   │   │   │   └── main.yml
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   └── README.md
│   ├── inventory/
│   │   └── hosts.yml
│   ├── site-ryzen.yml
│   └── README.md
└── README.md
```

---

## **🚀 Prochaines étapes**
1. **Standardiser** :
   - Appliquer ces règles aux nouveaux modules/rôles.
   - Mettre à jour les fichiers existants pour respecter les conventions.

2. **Automatiser** :
   - Ajouter des outils de linting (`tflint`, `ansible-lint`) dans ton workflow.
   - Configurer un pipeline CI/CD pour valider les changements.

3. **Documenter** :
   - Compléter les `README.md` des modules/rôles.
   - Ajouter des exemples d'utilisation.

4. **Sécuriser** :
   - Chiffrer les secrets avec `sops` ou `git-secret`.
   - Vérifier que `.env.json` est bien ignoré par Git.