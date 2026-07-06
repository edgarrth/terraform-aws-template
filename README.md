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
.github/workflows/
├── validate-standards.yml
└── deploy.yml

ansible/
├── ansible.cfg
├── inventory/aws_ec2.yml
├── group_vars/all/standards.yml
└── playbooks/baseline-linux.yml

docs/standards/
└── infra-standards.md

policy/
└── terraform_standards.rego

scripts/
├── validate-standards.sh
└── deploy.sh

terraform/
├── backend/
├── globals/
├── live/
│   ├── dev/
│   ├── qa/
│   └── prod/
└── modules/
    ├── dynamodb/
    ├── messaging/
    ├── networking/
    ├── eks/
    ├── ecr/
    ├── aurora-postgresql/
    ├── rds-postgresql/
    ├── documentdb/
    ├── elasticache-redis/
    ├── msk-kafka/
    ├── secrets-manager/
    ├── observability/
    ├── iam/
    ├── kms/
    └── waf/
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
acme-pay-platform-microservices-shared-dev-ue1-vpc
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

# Consideraciones FinOps

- Activar los Cost Allocation Tags en AWS Billing.
- Revisar costos de EKS, NAT Gateway, MSK, DocumentDB y endpoints privados.
- Usar `finops_allocation` para separar costos directos, compartidos, plataforma, seguridad, red y observabilidad.
- Los recursos experimentales deben tener `expiration_date`.
- Ambientes no productivos deben tener estrategia de apagado cuando aplique.

# Consideraciones de seguridad

- No usar acceso público salvo excepción.
- Usar cifrado con KMS en datos y mensajería.
- No guardar secretos en repositorio.
- Usar Secrets Manager.
- Aplicar mínimo privilegio en IAM.
- Revisar hallazgos de Checkov antes de merge.

# Pendientes recomendados para producción real

- AWS Organizations y SCPs.
- Control Tower Account Factory.
- GuardDuty y Security Hub organizacional.
- External Secrets Operator.
- AWS Load Balancer Controller.
- Karpenter.
- Network Policies.
- AWS Backup centralizado.
- GitOps con Argo CD.
- Service Mesh si existe necesidad real de mTLS, traffic shifting o políticas avanzadas.


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

La validación corporativa de naming, tags, FinOps y sintaxis Terraform es **bloqueante** y se ejecuta con `scripts/validate-standards.sh`.

Checkov se ejecuta como análisis de seguridad y genera SARIF, pero queda en modo **advisory/soft-fail** porque algunas reglas requieren decisiones organizacionales externas al template, por ejemplo AWS Backup centralizado, VPC Flow Logs centralizados, rotación de secretos con Lambda, logging WAF/MSK o políticas SCP/AWS Config.

Las exclusiones documentadas están en `.checkov.yml`.
