# Terraform module: network

Este documento describe el módulo `network` usado en `terraform/modules/network`.
Contiene la intención, contrato (inputs/outputs), la arquitectura creada por los ficheros `main.tf`/`variables.tf` y decisiones de diseño (por ejemplo usar una instancia EC2 como NAT en QA en lugar de NAT Gateway o ALB).

## Propósito

El módulo crea la capa de red necesaria para desplegar la aplicación en AWS:

- Una VPC con CIDR configurable.
- Subnets públicas y privadas (multi‑AZ si se suministran `azs`).
- Internet Gateway y tabla de rutas pública.
- Tabla de rutas privada y asociaciones con subnets privadas.
- Opción (condicional) de crear una instancia NAT (EC2 + EIP) en vez de NAT Gateway.
- Etiquetas comunes y outputs para consumo por otros módulos (compute, db, alb, etc.).

El módulo está orientado a entornos de desarrollo/QA con restricciones de coste. Para producción se recomienda utilizar patrones de alta disponibilidad (NAT Gateway / ALB) y seguridad adicional.

## Contrato (inputs relevantes)

- `name` (string): Nombre del entorno (ej. `movie-qa`).
- `vpc_cidr` (string): CIDR para la VPC (por defecto `10.10.0.0/16`).
- `azs` (list(string)): Lista de Availability Zones deseadas (si se deja vacía, se usan AZs disponibles).
- `public_subnets` (list(string)): CIDRs para subnets públicas (por AZ).
- `private_subnets` (list(string)): CIDRs para subnets privadas (por AZ).
- `map_public_ip_on_launch` (bool): Si las instancias en subnets públicas reciben IP pública.
- `enable_nat` (bool): Si `true` crea una instancia NAT EC2 + EIP.
- `tags` (map(string)): Tags comunes (el módulo añade `Environment` y `Project` si no existen).

Consulta `variables.tf` para el contrato completo y valores por defecto.

## Outputs recomendados

- `vpc_id` — ID del VPC.
- `public_subnet_ids` — IDs de las subnets públicas.
- `private_subnet_ids` — IDs de las subnets privadas.
- `nat_instance_id` — ID de la instancia NAT (si creada).
- `nat_public_ip` — IP pública asignada a la NAT (si creada).

Ejemplo de `outputs.tf` (sugerencia):

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "nat_instance_id" {
  value       = var.enable_nat ? aws_instance.nat[0].id : null
  description = "ID of NAT EC2 instance (if created)"
}

output "nat_public_ip" {
  value       = var.enable_nat ? aws_eip.nat[0].public_ip : null
  description = "Public IP assigned to NAT (if created)"
}
```

## Arquitectura y recursos clave (cómo trabaja)

1. Data sources
   - `aws_availability_zones.available` — se usa si `var.azs` está vacío para elegir AZs.
   - `aws_ssm_parameter.amzn2` — parameter store con el AMI de Amazon Linux 2 (usado para la instancia NAT si se crea).

2. VPC
   - `aws_vpc.this` con DNS habilitado.

3. Subnets
   - `aws_subnet.public` y `aws_subnet.private` creadas con `for_each` mapeando AZ→CIDR.

4. Internet Gateway y tablas públicas
   - `aws_internet_gateway.this`, `aws_route_table.public`, y `aws_route.public_default_route`.
   - `aws_route_table_association.public_assoc` asocia cada subnet pública a la RT pública.

5. Tabla privada y asociaciones
   - `aws_route_table.private` (tabla para subnets privadas).
   - `aws_route_table_association.private_assoc` asocia cada subnet privada.
   - `aws_route.private_to_nat` crea la ruta 0.0.0.0/0 apuntando a la interfaz de red primaria de la instancia NAT (si `enable_nat=true`). Esto es más estable que apuntar directamente a `instance_id` en algunas versiones del provider.

6. NAT (opcional)
   - `aws_eip.nat` — EIP usado por la instancia NAT (count condicional).
   - `aws_instance.nat` — instancia EC2 que ejecuta iptables/masquerade (user_data configura forwarding y reglas de SNAT).
   - `aws_eip_association.nat_assoc` — asocia la EIP con la instancia.

## Por qué EC2 NAT en QA (decisión de diseño)

- Coste: NAT Gateway tiene coste por hora y por datos transferidos. Para QA con tráfico bajo, una `t3.micro` con EIP es mucho más económica y puede encajar dentro del free‑tier.
- Control: la instancia EC2 permite ver logs, ajustar iptables y depurar tráfico (útil al aprender y testear).
- Simplicidad: evita costes operativos y acelera pruebas. En producción se recomienda NAT Gateway o NAT instances por AZ para alta disponibilidad.

## Por qué usar EC2 en vez de ALB en QA (para el caso del balanceo)

- ALB ofrece ventajas (TLS, health checks, escalado), pero tiene coste y añade complejidad.
- En QA con bajo tráfico, desplegar una o dos instancias EC2 y probar con su IP/DNS es suficiente.
- Para producción, añadir un módulo `alb` y usar Target Groups es la ruta correcta.

## Ejemplo de uso (root module)

```hcl
module "network" {
  source = "../../modules/network"

  name                   = "movie-qa"
  vpc_cidr               = "10.10.0.0/16"
  public_subnets         = ["10.10.1.0/24","10.10.2.0/24"]
  private_subnets        = ["10.10.101.0/24","10.10.102.0/24"]
  map_public_ip_on_launch = true
  enable_nat             = true
  tags = {
    Environment = "qa"
    Project     = "movie-analyst"
  }
}
```

## Troubleshooting rápido

- `Reference to undeclared resource aws_route_table.private` → falta declarar `aws_route_table.private`.
- `index out of range` al leer `aws_instance.nat[0]` → `enable_nat` está a `false` (count=0), probar con `-var='enable_nat=true'` para validar.
- `instance_id` no configurable → usar `network_interface_id = aws_instance.nat[0].primary_network_interface_id`.
- Si Terraform intenta crear rutas antes de la NAT: añadir temporalmente `depends_on = [aws_instance.nat]` en la ruta.

## Comandos para validar y planear

```bash
cd terraform/envs/qa
terraform fmt -recursive
terraform init
terraform validate
terraform plan -var='name=movie-qa' -var='enable_nat=true'
```

## Siguientes pasos recomendados

- Añadir `outputs.tf` sugerido para uso por `compute` y `db`.
- Crear un módulo `compute` que consuma `public_subnet_ids`/`private_subnet_ids` y configure Security Groups.
- Documentar un runbook para limpieza de recursos (stop/destroy) y checklist de costes.

---

Si quieres, puedo preparar un `diff` con este README listo para aplicar (no lo aplicaré sin tu permiso). ¿Deseas que lo deje como patch para revisar? 
# Terraform module: network (placeholder)

Este README describe el contrato esperado del módulo `network`.

- Propósito: crear VPC, subnets públicas/privadas y routing mínimo.
- Inputs esperados: vpc_cidr, public_subnets, private_subnets, azs
- Outputs esperados: vpc_id, public_subnet_ids, private_subnet_ids

NOTA: Este archivo es un placeholder. Implementa los `.tf` concretos cuando procedas.
