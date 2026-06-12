# Home Lab - Infrastructure as Code (IaC)

Ce projet automatise la gestion et le déploiement d'une infrastructure **Home Lab** sur **Proxmox** (ex: Ryzen, NUC).
Il utilise **Terraform** pour provisionner les ressources (LXC, VM, stockage) et **Ansible** pour configurer les services et applications.

---

## 🎯 Objectif
Automatiser la création, la configuration et la gestion d'une infrastructure **Home Lab** scalable et reproductible, avec :
- Déploiement de conteneurs LXC pour des services (ex: `apps_runner`, `AI`).
- Configuration avancée (GPU Passthrough, stockage, réseau).
- Gestion centralisée des secrets et des configurations.

---

## 📁 Structure du Projet

### **1. Répertoires Principaux**
| Répertoire       | Description                                                                                     |
|------------------|-------------------------------------------------------------------------------------------------|
| `terraform/`     | Configurations Terraform pour provisionner les ressources (LXC, VM, stockage).                |
| `ansible/`       | Playbooks et rôles Ansible pour configurer les services et applications.                       |
| `.env.json`      | Fichier de secrets (ignoré par Git). **Ne jamais commiter ce fichier !**                       |
| `RULES.md`       | [Bonnes pratiques et conventions](./RULES.md) pour Terraform et Ansible.                       |
| `AGENTS.md`      | Configuration des agents pour automatiser les tâches (linting, tests).                         |

---

## 🛠️ Terraform

### **Structure**
- **Modules** : Réutilisables pour créer des ressources (ex: [`lxc`](./terraform/modules/lxc/)).
- **Environnements** : Configurations spécifiques (ex: [`ryzen`](./terraform/environments/ryzen/)).

### **Bonnes Pratiques**
- Variables typées avec descriptions (ex: `variable "cpu_cores" { ... }`).
- Secrets centralisés dans `.env.json`.
- Validation avec `terraform validate` et `tflint`.

### **Exemple de Déploiement**
```bash
cd terraform/environments/ryzen
terraform init
terraform plan
terraform apply
```

---

## 🔧 Ansible

### **Structure**
- **Rôles** : Configurations réutilisables (ex: [`ai`](./ansible/roles/ai/) pour GPU Passthrough).
- **Playbooks** : Orchestration (ex: [`site-ryzen.yml`](./ansible/site-ryzen.yml)).
- **Inventaire** : Hôtes et groupes (ex: [`inventory/hosts.yml`](./ansible/inventory/hosts.yml)).

### **Bonnes Pratiques**
- Tâches découpées en sous-fichiers (ex: `tasks/gpu.yml`).
- **Vérifications + corrections automatiques** (ex: réinstaller Docker si échec).
- Validation avec `ansible-lint`.

### **Exemple de Déploiement**
```bash
ansible-playbook ansible/site-ryzen.yml -i ansible/inventory/hosts.yml
```

---

## 🚀 Déploiement et Tests

### **1. Prérequis**
- **Terraform** ≥ 1.0, **Ansible** ≥ 2.10.
- Outils : `tflint`, `ansible-lint`, `molecule`.

### **2. Étapes**
1. **Cloner le dépôt** :
   ```bash
   git clone <url_du_depot>
   cd home-lab
   ```

2. **Configurer les secrets** :
   - Créer `.env.json` (exemple dans [`RULES.md`](./RULES.md)).

3. **Provisionner avec Terraform** :
   ```bash
   cd terraform/environments/ryzen
   terraform apply
   ```

4. **Configurer avec Ansible** :
   ```bash
   ansible-playbook ansible/site-ryzen.yml -i ansible/inventory/hosts.yml
   ```

---

### **3. Tests**
#### **Terraform**
```bash
terraform validate
tflint
```

#### **Ansible**
```bash
ansible-lint ansible/site-ryzen.yml
cd ansible/roles/ai && molecule test
```

---

## 🤝 Contribuer
- Consulter [`RULES.md`](./RULES.md) pour les conventions.
- Créer une branche pour chaque fonctionnalité :
  ```bash
  git checkout -b feature/<nom>
  ```
- Valider avec les outils de linting avant toute PR.

---

## 📄 Licence
MIT. Voir [LICENSE](./LICENSE).