🏠 Home-Lab Infra
Dépôt IaC pour la gestion de mon infrastructure personnelle sur Proxmox (Ryzen).

🛠 Stack
Provisioning : Terraform (LXC Debian 12)

Configuration : Ansible (Services & Stockage)

📂 Structure
/terraform : Déploiement des ressources.

/ansible : Post-installation et configuration logicielle.

🚀 Quick Start
Bash
# 1. Infrastructure
cd terraform && terraform apply

# 2. Configuration
cd ansible && ansible-playbook -i inventory.ini playbook.yml