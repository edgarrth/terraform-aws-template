# Ansible

Este directorio contiene configuraciones opcionales para recursos donde Ansible sí aplica, principalmente EC2 administradas fuera de EKS o nodos especiales.

No se usa Ansible para crear servicios administrados AWS. Eso se mantiene en Terraform.

# Ejecutar

```bash
cd ansible
ansible-galaxy collection install amazon.aws ansible.posix
ansible-playbook playbooks/baseline-linux.yml
```
