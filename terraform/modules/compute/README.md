# Terraform module: compute (skeleton)

Este módulo desplegará instancias EC2 para roles como `bastion` y `app`.

Arquitectura objetivo:
- Bastion: en subnet pública, acceso SSH limitado.
- App: en subnet privada, desplegada por Ansible desde Bastion.

Inputs esperados:
- `vpc_id`, `public_subnet_ids`, `private_subnet_ids` (consumir outputs del módulo network)
- `key_name`, `instance_type`, `ami`, `tags`.

Outputs:
- `bastion_id`, `bastion_public_ip`, `app_instance_ids`, `app_private_ips`.

NOTA: Este esqueleto no crea recursos por defecto. Implementa los `.tf` concretos cuando estés listo.
# Terraform module: compute (placeholder)

Propósito: definir recursos de EC2/ASG/ECS según el diseño. Inputs/outputs por definir.
