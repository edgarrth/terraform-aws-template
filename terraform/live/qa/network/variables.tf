variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "common_tags" {
  type    = map(string)
  default = {
} }

locals {
  required_tags = {
    organization        = "acme"
    business_unit       = "pay"
    domain              = "platform"
    application         = "microservices"
    component           = "shared"
    owner               = "platform-team"
    technical_owner     = "architecture"
    cost_center         = "cc-technology"
    product             = "microservices-platform"
    squad               = "platform-squad"
    criticality         = "medium"
    data_classification = "internal"
    compliance          = "internal"
    managed_by          = "terraform"
    repository          = "terraform-aws-template"
    lifecycle           = "active"
    backup_required     = "false"
    dr_required         = "false"
    finops_allocation   = "platform"
  }

  name = var.name_prefix

  tags = merge(local.required_tags, var.common_tags, {
    environment = var.environment
  })
}
