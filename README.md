# Terraform AWS Microservices Landing Zone

Repositorio de referencia para una plataforma AWS de microservicios con Terraform, estándares de naming/tagging/FinOps, validación automática con OPA/Conftest, seguridad IaC con Checkov y configuración opcional con Ansible.

# Arquitectura incluida

```text
Foundation
├── KMS
└── IAM roles para EKS

Network
├── VPC
├── Public subnets
├── Private subnets
├── Database subnets
├── Internet Gateway
├── NAT Gateway
├── Route Tables
├── DB Subnet Group
├── Gateway Endpoint S3
└── Interface Endpoints: ECR, Logs, Secrets Manager, KMS, STS, SNS y SQS

Platform
├── EKS
├── EKS managed node group
├── EKS addons
├── ECR repositories
└── WAF

Data
├── Aurora PostgreSQL
├── DocumentDB
├── ElastiCache Redis
├── MSK Kafka
├── DynamoDB
├── SNS
├── SQS
├── SQS DLQ
└── Secrets Manager

Observability
├── CloudWatch Log Groups
├── SNS topic de alertas
└── CloudWatch Alarms base

Governance
├── Estándares de naming
├── Tags FinOps obligatorios
├── Validación OPA/Conftest
├── Checkov
└── GitHub Actions separado para validación y despliegue
```

# Estructura

```text
.github/
└── workflows/                    # Pipelines de GitHub Actions para validación y despliegue.
    ├── validate-standards.yml    # Valida estándares, Terraform y políticas de seguridad.
    └── deploy.yml                # Despliega la infraestructura mediante Terraform.

ansible/                          # Automatización de configuración posterior al aprovisionamiento.
├── ansible.cfg                   # Configuración global de Ansible.
├── inventory/
│   └── aws_ec2.yml               # Inventario dinámico utilizando AWS EC2.
├── group_vars/
│   └── all/
│       └── standards.yml         # Variables y configuraciones comunes.
└── playbooks/
    └── baseline-linux.yml        # Configuración base para instancias Linux.

docs/
└── standards/                    # Documentación de estándares de infraestructura.
    └── infra-standards.md        # Naming conventions, tagging, FinOps y buenas prácticas.

policy/                           # Políticas corporativas utilizadas durante la validación.
└── terraform_standards.rego      # Reglas OPA/Rego para validar Terraform.

scripts/                          # Scripts utilizados por CI/CD y despliegues locales.
├── validate-standards.sh         # Ejecuta validaciones de formato, estándares y Terraform.
└── deploy.sh                     # Ejecuta el despliegue automatizado.

terraform/                        # Código de infraestructura como código (IaC).
├── backend/                      # Configuración del backend remoto para el estado de Terraform.
├── globals/                      # Variables, etiquetas y configuraciones compartidas.
├── live/                         # Configuración por ambiente.
│   ├── dev/                      
│   ├── qa/                       
│   └── prod/                     
└── modules/                      # Módulos reutilizables de infraestructura.
    ├── networking/               # VPC, subnets, NAT, route tables, endpoints y networking.
    ├── eks/                      # Cluster Amazon EKS y Node Groups.
    ├── ecr/                      # Repositorios de imágenes Docker.
    ├── iam/                      # Roles, políticas y permisos IAM.
    ├── kms/                      # Claves de cifrado KMS.
    ├── secrets-manager/          # Gestión de secretos.
    ├── messaging/                # SNS y SQS para mensajería asíncrona.
    ├── dynamodb/                 # Tablas DynamoDB.
    ├── aurora-postgresql/        # Clúster Aurora PostgreSQL.
    ├── rds-postgresql/           # Instancias RDS PostgreSQL.
    ├── documentdb/               # Clústeres Amazon DocumentDB.
    ├── elasticache-redis/        # Clústeres ElastiCache Redis.
    ├── msk-kafka/                # Amazon MSK (Kafka administrado).
    ├── observability/            # CloudWatch, alarmas y monitoreo.
    └── waf/                      # AWS WAF para protección de aplicaciones.
```

# Estándares

Los estándares completos están en:

```text
docs/standards/infra-standards.md
```

# Naming convention

Formato base:

```text
{org}-{bu}-{domain}-{app}-{component}-{env}-{region}-{resource_type}
```

Ejemplo:

```text
axiz-pay-platform-microservices-shared-dev-ue1-vpc
```

# Tags obligatorios

Todo recurso debe incluir como mínimo:

```text
organization
business_unit
domain
application
component
environment
owner
technical_owner
cost_center
product
squad
criticality
data_classification
compliance
managed_by
repository
lifecycle
backup_required
dr_required
finops_allocation
```

# Orden de despliegue

Por ambiente:

```bash
./scripts/deploy.sh dev foundation plan
./scripts/deploy.sh dev network plan
./scripts/deploy.sh dev platform plan
./scripts/deploy.sh dev data plan
./scripts/deploy.sh dev observability plan
```

Para aplicar:

```bash
./scripts/deploy.sh dev foundation apply
```

Repetir para `qa` y `prod`.

# Validación local de estándares

Requisitos:

- Terraform >= 1.6
- Conftest
- Checkov opcional para ejecución local

Ejecutar todo un ambiente:

```bash
./scripts/validate-standards.sh dev all
```

Ejecutar una capa específica:

```bash
./scripts/validate-standards.sh dev network
```

# GitHub Actions

# 1. Validación

Workflow:

```text
.github/workflows/validate-standards.yml
```

Requiere configurar el secreto:

```text
AWS_READONLY_ROLE_ARN
```

Valida:

- `terraform fmt`
- `terraform validate`
- `terraform plan`
- Políticas corporativas con OPA/Conftest
- Seguridad IaC con Checkov

# 2. Despliegue

Workflow:

```text
.github/workflows/deploy.yml
```

El despliegue es manual con `workflow_dispatch` y permite seleccionar:

- Ambiente: `dev`, `qa`, `prod`
- Layer: `foundation`, `network`, `platform`, `data`, `observability`
- Acción: `plan`, `apply`

Requiere configurar el secreto:

```text
AWS_DEPLOY_ROLE_ARN
```

# Backend remoto

Antes de aplicar, crear por ambiente:

- Bucket S3 para estado Terraform.
- Tabla DynamoDB para locking.

Archivos:

```text
terraform/backend/dev.hcl
terraform/backend/qa.hcl
terraform/backend/prod.hcl
```

# Ansible

Ansible se incluye solo para configuraciones donde aplica, principalmente baseline Linux en EC2 administradas.

No se usa Ansible para crear servicios administrados AWS. Esa responsabilidad queda en Terraform.

Ejemplo:

```bash
cd ansible
ansible-galaxy collection install amazon.aws ansible.posix
ansible-playbook playbooks/baseline-linux.yml
```

## GitHub Actions

### Validación de estándares

El workflow `.github/workflows/validate-standards.yml` valida naming conventions, tags FinOps, formato Terraform, `terraform validate` y Checkov.

Este workflow **no requiere credenciales AWS** porque no ejecuta `terraform plan` ni consulta recursos cloud. Está diseñado para correr en pull requests y por ejecución manual.

Ejecución local equivalente:

```bash
./scripts/validate-standards.sh dev all
./scripts/validate-standards.sh prod data
```

### Despliegue

El workflow `.github/workflows/deploy.yml` sí requiere OIDC y el secret `AWS_DEPLOY_ROLE_ARN`, porque ejecuta `terraform plan` o `terraform apply` contra AWS.


## Nota sobre Checkov

La validación corporativa de naming, tags, FinOps y sintaxis Terraform 
es **bloqueante** y se ejecuta con `scripts/validate-standards.sh`.

Checkov se ejecuta como análisis de seguridad y genera SARIF, 
pero queda en modo **advisory/soft-fail** porque algunas reglas 
requieren decisiones organizacionales externas al template, 
por ejemplo AWS Backup centralizado, VPC Flow Logs centralizados, 
rotación de secretos con Lambda, logging WAF/MSK o políticas SCP/AWS Config.

Las exclusiones documentadas están en `.checkov.yml`.
