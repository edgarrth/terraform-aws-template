module "kms" {
  source      = "../../../modules/kms"
  name        = "${local.name}-platform"
  description = "KMS key for ${local.name} platform"
  tags        = local.tags
}

module "iam" {
  source      = "../../../modules/iam"
  name_prefix = local.name
  tags        = local.tags
}
