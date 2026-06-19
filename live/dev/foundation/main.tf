module "kms" {
  source      = "../../../modules/kms"
  alias_name  = "alias/${var.name_prefix}/platform"
  description = "KMS key for ${var.name_prefix} microservices platform"
  tags        = var.tags
}

module "iam" {
  source      = "../../../modules/iam"
  name_prefix = var.name_prefix
  tags        = var.tags
}
