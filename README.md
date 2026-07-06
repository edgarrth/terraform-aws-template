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
├── live/                         # Configuración por workload y luego por ambiente.
│   └── payments/                 # Workload de ejemplo reutilizable para dominios/productos.
│       ├── dev/                  # Ambiente de desarrollo del workload.
│       ├── qa/                   # Ambiente de pruebas del workload.
│       └── prod/                 # Ambiente productivo del workload.
└── modules/                      # Módulos reutilizables agrupados por dominio de Landing Zone.
    ├── foundation/               # Servicios base de identidad, seguridad y cifrado.
    │   ├── iam/                  # Roles, políticas y permisos IAM.
    │   └── kms/                  # Claves de cifrado KMS.
    ├── network/                  # Red spoke del workload.
    │   └── networking/           # VPC, subnets, NAT, route tables, endpoints y networking.
    ├── platform/                 # Plataforma de ejecución de microservicios.
    │   ├── eks/                  # Cluster Amazon EKS y Node Groups.
    │   ├── ecr/                  # Repositorios de imágenes Docker.
    │   └── waf/                  # AWS WAF para protección de aplicaciones.
    ├── data/                     # Servicios de persistencia, mensajería y secretos.
    │   ├── aurora-postgresql/    # Clúster Aurora PostgreSQL.
    │   ├── rds-postgresql/       # Instancias RDS PostgreSQL.
    │   ├── documentdb/           # Clústeres Amazon DocumentDB.
    │   ├── dynamodb/             # Tablas DynamoDB.
    │   ├── elasticache-redis/    # Clústeres ElastiCache Redis.
    │   ├── messaging/            # SNS, SQS y DLQ para mensajería asíncrona.
    │   ├── msk-kafka/            # Amazon MSK (Kafka administrado).
    │   └── secrets-manager/      # Gestión de secretos.
    ├── observability/            # Monitoreo, logging y alarmas.
    │   └── cloudwatch/           # CloudWatch Logs, alarmas y alertas.
    └── governance/               # Estándares, políticas y validaciones sin recursos AWS directos.
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

Por workload y ambiente:

```bash
./scripts/deploy.sh payments dev foundation plan
./scripts/deploy.sh payments dev network plan
./scripts/deploy.sh payments dev platform plan
./scripts/deploy.sh payments dev data plan
./scripts/deploy.sh payments dev observability plan
```

Para aplicar:

```bash
./scripts/deploy.sh payments dev foundation apply
```

Repetir para `qa` y `prod`.

# Validación local de estándares

Requisitos:

- Terraform >= 1.6
- Conftest
- Checkov opcional para ejecución local

Ejecutar todo un ambiente:

```bash
./scripts/validate-standards.sh payments dev all
```

Ejecutar una capa específica:

```bash
./scripts/validate-standards.sh payments dev network
```

# GitHub Actions

# 1. Validación

Workflow:

```text
.github/workflows/validate-standards.yml
```

No requiere credenciales AWS para validación local o pull requests.

Valida:

- `terraform fmt`
- `terraform validate`
- Políticas corporativas con OPA/Conftest
- Seguridad IaC con Checkov

# 2. Despliegue

Workflow:

```text
.github/workflows/deploy.yml
```

El despliegue es manual con `workflow_dispatch` y permite seleccionar:

- Workload: `payments`
- Ambiente: `dev`, `qa`, `prod`
- Layer: `foundation`, `network`, `platform`, `data`, `observability`
- Acción: `plan`, `apply`

Requiere configurar el secreto:

```text
AWS_DEPLOY_ROLE_ARN
```

# Backend remoto

Antes de aplicar, crear por ambiente y workload:

- Bucket S3 para estado Terraform.
- Tabla DynamoDB para locking.
- Claves de estado con formato `workload/environment/layer/terraform.tfstate`, por ejemplo `payments/dev/platform/terraform.tfstate`.

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

El workflow `.github/workflows/validate-standards.yml` valida naming conventions, tags FinOps, formato Terraform, `terraform validate` y Checkov por workload, ambiente y layer.

Este workflow **no requiere credenciales AWS** porque no ejecuta `terraform plan` ni consulta recursos cloud. Está diseñado para correr en pull requests y por ejecución manual.

Ejecución local equivalente:

```bash
./scripts/validate-standards.sh payments dev all
./scripts/validate-standards.sh payments prod data
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

# Landing Zone

Recomendacin de landing inicial

```text
AWS Organization                           # Organización AWS completa
│
├── Management Account                     # Cuenta raíz operativa de Control Tower / Organizations
│
├── Security OU                            # OU de seguridad creada por la Landing Zone
│   ├── Log Archive Account                # Cuenta para logs centralizados
│   └── Audit Account                      # Cuenta para auditoría y seguridad
│
├── Infrastructure OU                      # OU de infraestructura compartida
│   ├── Network Account                    # Cuenta del Network Hub
│   │   ├── Transit Gateway
│   │   ├── Inspection VPC
│   │   ├── Egress VPC
│   │   ├── Network Firewall
│   │   ├── Route53 Resolver
│   │   ├── Direct Connect / VPN
│   │   └── Shared VPC Endpoints
│   │
│   └── Shared Services Account            # Cuenta de servicios compartidos
│       ├── Logging centralizado
│       ├── Observabilidad central
│       ├── ECR compartido
│       ├── KMS compartido
│       └── Secrets / parámetros compartidos
│
├── Workloads OU                           # OU de aplicaciones/productos (Spokes)
│   ├── Payments Dev Account               # Cuenta de workload no productivo
│   ├── Payments QA Account                # Cuenta de workload QA
│   └── Payments Prod Account              # Cuenta de workload productivo
│       ├── Foundation
│       ├── Network Spoke
│       ├── Platform
│       ├── Data
│       ├── Observability
│       └── Governance
│
└── Data OU                                # OU opcional para plataforma de datos
    └── Data Platform Account              # Cuenta de data lake / data warehouse
        ├── Data Lake
        ├── Data Warehouse
        ├── Data Integration
        ├── Analytics
        └── Data Governance
```

Flujo hub and spoke recomendado:
```text
                HUB
      +----------------------+
      |  Network Account     |
      |----------------------|
      | Hub VPC              |
      | Transit Gateway      |
      | Firewall             |
      | Route53              |
      | DX / VPN             |
      +----------+-----------+
                 |
      -----------------------------
      |             |            |
      |             |            |
+-----------+ +-----------+ +-----------+
| Spoke VPC | | Spoke VPC | | Spoke VPC |
| Payments  | | Customers | | Loans     |
+-----------+ +-----------+ +-----------+
```

Chart del landing

```mermaid
flowchart TB

  ORG["AWS Organization<br/>Organización AWS completa"]

  MGMT["Management Account<br/>Control Tower / Organizations"]

  SEC_OU["Security OU"]
  LOG["Log Archive Account<br/>Logs centralizados"]
  AUDIT["Audit Account<br/>Auditoría y seguridad"]

  INFRA_OU["Infrastructure OU"]

  HUB["Hub Network Account<br/>HUB"]
  TGW["Transit Gateway"]
  HUBVPC["Hub / Inspection VPC"]
  EGRESS["Egress VPC"]
  FW["Network Firewall"]
  DNS["Route53 Resolver"]
  DX["Direct Connect / VPN"]
  VPCE["Shared VPC Endpoints"]

  SHARED["Shared Services Account"]
  CLOG["Logging centralizado"]
  COBS["Observabilidad central"]
  CECR["ECR compartido"]
  CKMS["KMS compartido"]
  CSEC["Secrets / parámetros compartidos"]

  WORK_OU["Workloads OU<br/>SPOKES"]

  PAY_DEV["Payments Dev Account<br/>Spoke"]
  PAY_QA["Payments QA Account<br/>Spoke"]
  PAY_PRD["Payments Prod Account<br/>Spoke"]

  SPOKE_NET["Network Spoke<br/>Workload VPC + TGW Attachment"]
  FOUNDATION["Foundation"]
  PLATFORM["Platform<br/>EKS / ECR / WAF"]
  DATA["Data<br/>Aurora / DynamoDB / Redis / SNS / SQS"]
  OBS["Observability"]
  GOV["Governance"]

  DATA_OU["Data OU"]
  DATA_ACC["Data Platform Account"]
  DLAKE["Data Lake"]
  DWH["Data Warehouse"]
  DINT["Data Integration"]
  ANALYTICS["Analytics"]
  DGOV["Data Governance"]

  ORG --> MGMT
  ORG --> SEC_OU
  ORG --> INFRA_OU
  ORG --> WORK_OU
  ORG --> DATA_OU

  SEC_OU --> LOG
  SEC_OU --> AUDIT

  INFRA_OU --> HUB
  INFRA_OU --> SHARED

  HUB --> TGW
  HUB --> HUBVPC
  HUB --> EGRESS
  HUB --> FW
  HUB --> DNS
  HUB --> DX
  HUB --> VPCE

  SHARED --> CLOG
  SHARED --> COBS
  SHARED --> CECR
  SHARED --> CKMS
  SHARED --> CSEC

  WORK_OU --> PAY_DEV
  WORK_OU --> PAY_QA
  WORK_OU --> PAY_PRD

  PAY_PRD --> FOUNDATION
  PAY_PRD --> SPOKE_NET
  PAY_PRD --> PLATFORM
  PAY_PRD --> DATA
  PAY_PRD --> OBS
  PAY_PRD --> GOV

  SPOKE_NET -. "TGW Attachment" .-> TGW
  PAY_DEV -. "TGW Attachment" .-> TGW
  PAY_QA -. "TGW Attachment" .-> TGW

  DATA_OU --> DATA_ACC
  DATA_ACC --> DLAKE
  DATA_ACC --> DWH
  DATA_ACC --> DINT
  DATA_ACC --> ANALYTICS
  DATA_ACC --> DGOV
 ```

