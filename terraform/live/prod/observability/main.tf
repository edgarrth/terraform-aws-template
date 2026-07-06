module "observability" {
  source             = "../../../modules/observability"
  name_prefix        = local.name
  log_retention_days = 90
  tags               = local.tags
}
