# Estándares de infraestructura, naming, tagging y FinOps

# 1. Objetivo

Definir las reglas mínimas para nombrar, etiquetar, validar y operar recursos de infraestructura AWS y Kubernetes para una arquitectura profesional de microservicios.

# 2. Principios

- Todo recurso debe ser creado mediante IaC.
- Todo recurso debe tener dueño técnico, squad, aplicación, dominio, ambiente y centro de costo.
- Todo recurso productivo debe tener cifrado, backup y trazabilidad de costos cuando aplique.
- Todo recurso compartido debe indicar su estrategia de asignación FinOps.
- Todo cambio debe pasar por validación automática en CI/CD.
- Los nombres deben ser predecibles, legibles y automatizables.

# 3. Convención de nombres

# 3.1 Formato base

```text
{org}-{bu}-{domain}-{app}-{component}-{env}-{region}-{resource_type}
```

# 3.2 Reglas

- Usar minúsculas.
- Usar `kebab-case`.
- No usar espacios, `_`, caracteres especiales ni nombres personales.
- Incluir siempre ambiente.
- No incluir datos sensibles.
- Mantener nombres cortos para compatibilidad con Kubernetes y AWS.

# 3.3 Ejemplo

```text
acme-pay-platform-microservices-shared-dev-ue1-vpc
```

# 4. Ambientes

| Código | Uso |
|---|---|
| dev | Desarrollo |
| qa | Calidad |
| stg | Staging |
| uat | Validación usuario |
| prod | Producción |
| dr | Disaster Recovery |
| sbx | Sandbox |

# 5. Tags obligatorios

| Tag | Ejemplo | Descripción |
|---|---|---|
| organization | acme | Organización |
| business_unit | pay | Unidad de negocio |
| domain | platform | Dominio |
| application | microservices | Aplicación o producto |
| component | shared | Componente |
| environment | dev | Ambiente |
| owner | platform-team | Equipo dueño |
| technical_owner | architecture | Responsable técnico |
| cost_center | cc-technology | Centro de costo |
| product | microservices-platform | Producto |
| squad | platform-squad | Squad responsable |
| criticality | medium | Criticidad |
| data_classification | internal | Clasificación de datos |
| compliance | internal | Cumplimiento aplicable |
| managed_by | terraform | Herramienta de gestión |
| repository | terraform-aws-template | Repositorio fuente |
| lifecycle | active | Ciclo de vida |
| backup_required | false | Requiere backup |
| dr_required | false | Requiere DR |
| finops_allocation | platform | Tipo de asignación FinOps |

# 6. Valores permitidos

```text
environment: dev | qa | stg | uat | prod | dr | sbx
criticality: low | medium | high | critical
data_classification: public | internal | confidential | restricted
managed_by: terraform | terragrunt | helm | argocd | ansible | manual-exception
lifecycle: experimental | active | deprecated | retired
finops_allocation: direct | shared | platform | security | networking | observability
backup_required: true | false
dr_required: true | false
```

# 7. Reglas FinOps

- Los tags de asignación de costos deben activarse como Cost Allocation Tags en la cuenta AWS.
- Los costos `direct` se asignan a una aplicación, squad y centro de costo.
- Los costos `shared` deben tener una regla de distribución definida.
- Los costos `platform`, `security`, `networking` y `observability` deben reportarse como costos compartidos de plataforma.
- Todo recurso `experimental` debe tener `expiration_date`.
- Todo ambiente no productivo debe tener estrategia de apagado o justificación.

# 8. Reglas por recurso

| Recurso | Regla mínima |
|---|---|
| VPC/Subnets | Nombre estándar, tags, subnets públicas, privadas y data separadas |
| Security Group | Sin exposición amplia salvo excepción; descripción obligatoria |
| EKS | Logs de control plane habilitados, subnets privadas, node groups etiquetados |
| ECR | Scan on push, tags inmutables, lifecycle policy |
| RDS/Aurora/PostgreSQL | Cifrado, backup, subnet privada, no público |
| DynamoDB | Cifrado, PITR cuando aplique, tags FinOps |
| SQS | DLQ para colas críticas, cifrado, retention definido |
| SNS | Cifrado, tags, suscripciones controladas |
| MSK/Kafka | Cifrado, logs, versionado de topics |
| S3 | Bloqueo público, cifrado, versioning si aplica |
| Secrets Manager | KMS, rotación cuando aplique, sin secretos en código |
| CloudWatch | Retención definida y tags |

# 9. Validación obligatoria

El pipeline debe validar:

- Formato de nombres.
- Tags obligatorios.
- Valores permitidos.
- Cifrado en recursos de datos y mensajería.
- Backups en producción.
- Exposición pública no autorizada.
- Uso de Terraform fmt/validate.
- Seguridad IaC con Checkov.
- Políticas corporativas con OPA/Conftest.
