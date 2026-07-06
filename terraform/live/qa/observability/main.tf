module "observability" {
  source             = "../../../modules/observability"
  name_prefix        = local.name
  log_retention_days = 30
  tags               = local.tags
}
