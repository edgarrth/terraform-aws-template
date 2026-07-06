# Terraform AWS Microservices Landing Zone

Ejemplo de landing zone para microservicios Java en AWS usando servicios administrados:

- Amazon EKS para Kubernetes.
- Amazon RDS PostgreSQL.
- Amazon DocumentDB para compatibilidad MongoDB.
- Amazon ElastiCache Redis.
- Amazon MSK Kafka.
- Amazon ECR.
- AWS KMS, IAM, Secrets Manager, CloudWatch y WAF.

## Estructura

```text
terraform/
├── modules/                  # Módulos reutilizables
├── live/dev/                  # Composición ambiente dev
├── live/qa/                   # Composición ambiente qa
├── live/prod/                 # Composición ambiente prod
├── backend/                   # Backend S3 por ambiente
└── globals/                   # Variables globales de referencia
```

## Orden de despliegue

Por ambiente:

```bash
cd live/dev/foundation
terraform init -backend-config=../../../backend/dev.hcl -backend-config="key=dev/foundation/terraform.tfstate"
terraform apply

cd ../network
terraform init -backend-config=../../../backend/dev.hcl -backend-config="key=dev/network/terraform.tfstate"
terraform apply

cd ../platform
terraform init -backend-config=../../../backend/dev.hcl -backend-config="key=dev/platform/terraform.tfstate"
terraform apply

cd ../data
terraform init -backend-config=../../../backend/dev.hcl -backend-config="key=dev/data/terraform.tfstate"
terraform apply

cd ../observability
terraform init -backend-config=../../../backend/dev.hcl -backend-config="key=dev/observability/terraform.tfstate"
terraform apply
```

Repetir para `qa` y `prod`, cambiando el backend y la carpeta.

## Antes de aplicar

1. Crear manualmente o con bootstrap los buckets S3 y tablas DynamoDB para el remote state.
2. Cambiar los IDs de cuenta en `globals/accounts.tfvars`.
3. Cambiar nombres de buckets en `backend/*.hcl`.
4. Ajustar CIDRs, tamaños de instancia y región.
5. Revisar costos: MSK, DocumentDB, NAT Gateway y EKS generan costo aunque no haya tráfico.

# Recomendacion landing zone

Para producción se recomienda agregar:

- SCPs con AWS Organizations.
- AWS Control Tower Account Factory.
- GuardDuty y Security Hub organizacional.
- IRSA/EKS Pod Identity por microservicio.
- AWS Load Balancer Controller vía Helm/GitOps.
- External Secrets Operator.
- Karpenter.
- Network Policies.
- Backups centralizados con AWS Backup.

- 
## Landing Zone
```text
├── Foundation
│   ├── Organizations
│   ├── Control Tower
│   ├── IAM Identity Center
│   └── SCPs
├── Network
│   ├── VPCs
│   ├── Subnets
│   ├── Transit Gateway
│   ├── VPC Endpoints
│   └── DNS
├── Security
│   ├── KMS
│   ├── CloudTrail
│   ├── GuardDuty
│   ├── Security Hub
│   └── Secrets Manager
├── Platform
│   ├── EKS
│   ├── ECR
│   ├── Ingress
│   ├── Service Mesh
│   └── GitOps
├── Data
│   ├── RDS PostgreSQL
│   ├── DocumentDB
│   ├── ElastiCache Redis
│   └── MSK Kafka
├── Observability
│   ├── Logs
│   ├── Metrics
│   ├── Traces
│   └── Alerts
└── Governance
    ├── Tagging
    ├── Cost Management
    ├── Backup
    ├── DR
    └── Compliance
```
