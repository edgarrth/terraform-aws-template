module "observability" {
  source             = "../../../../modules/observability/cloudwatch"
  name_prefix        = local.name
  log_retention_days = 30
  tags               = local.tags
}
