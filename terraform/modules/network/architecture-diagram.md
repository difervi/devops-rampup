# Diagrama de arquitectura - módulo `network`

Archivo: `architecture-diagram.svg`

Este documento explica el diagrama SVG incluido y detalla cada componente, su propósito y recomendaciones operativas.

## Vista general (qué muestra el diagrama)

- VPC principal (`movie-qa`) con CIDR 10.10.0.0/16.
- Subnets públicas y privadas distribuidas entre AZs (ejemplo: `us-east-1a`, `us-east-1b`).
- Internet Gateway (IGW) conectando las subnets públicas a Internet.
- Bastion host en subnet pública para administración/Ansible.
- NAT implementado como una instancia EC2 (NAT instance) con EIP asociado — usada por las subnets privadas para salida a Internet.
- Instancias de la aplicación en subnets privadas y RDS MySQL en subnets privadas (acceso restringido mediante Security Groups).

## Elementos y propósito

- VPC: contenedor lógico de red.
- Subnet pública: recursos que necesitan IP pública o acceso directo (Bastion, ALB, NAT instance si se asocia a subnet pública).
- Subnet privada: recursos sin exposición pública (App EC2, RDS).
- IGW: permite que recursos en subnets públicas alcancen Internet.
- NAT EC2 + EIP: permite que instancias en subnets privadas hagan requests salientes (actualizaciones, conexiones a APIs externas) sin exponer sus IP privadas.
- Route tables: tabla pública apunta a IGW; tabla privada apunta al NAT (instancia EC2) para 0.0.0.0/0.

## Flujo de red típico

1. Una instancia en la subnet privada (App EC2) necesita descargar una dependencia desde Internet.
2. El paquete sale por la ruta 0.0.0.0/0 de la tabla privada y llega a la instancia NAT (EC2) mediante la ruta que apunta a su interfaz de red.
3. La instancia NAT hace SNAT (iptables MASQUERADE) y envía la petición hacia IGW usando su EIP. La respuesta regresa a la NAT y se enruta de vuelta a la App.

## Seguridad y permisos

- Security Group de RDS: sólo permite tráfico MySQL (TCP 3306) desde el Security Group de App o la IP del Bastion.
- Bastion: restringir acceso SSH a un rango IP permitido (tu oficina o VPN). Usar claves y rotación.
- NAT instance: restringir SSH también; preferir acceso sólo vía Bastion.

## Por qué esta arquitectura en QA

- Minimiza costes (NAT Gateway y ALB tienen tarifas que pueden superar el free‑tier). Una t3.micro con EIP reduce el coste para testing.
- Facilita debugging: al tener iptables en la NAT puedes inspeccionar reglas / logs.
- Simplicidad para despliegues rápidos y revertir cambios.

## Limitaciones y recomendaciones para Prod

- Alta disponibilidad: la NAT instance es un single‑point‑of‑failure; para Prod usar NAT Gateway o implementar NAT instances por AZ y rutas por AZ.
- Balanceo: usar ALB para TLS, health checks y escalado automático en Prod.
- Monitorización: instalar CloudWatch Agent en instancias, crear dashboards y alarmas para CPU, conexiones, tráfico de red y latencia.

## Cómo integrar con otros módulos

- `compute`: consume `public_subnet_ids` y `private_subnet_ids` para colocar instancias según su rol.
- `db`: consume `private_subnet_ids` para crear `aws_db_subnet_group` y desplegar RDS.
- `bastion`: puede ser un módulo que reciba `public_subnet_ids` y cree una instancia con una key pair y SGs específicos.

## Archivos incluidos

- `architecture-diagram.svg` — diagrama visual.
- `architecture-diagram.md` — este documento explicativo.

---

Si quieres que genere una versión PNG (por compatibilidad con presentaciones) o una versión con más detalle por AZ (NAT por AZ, múltiples RTs), dímelo y la creo.
