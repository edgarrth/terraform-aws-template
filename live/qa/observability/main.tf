module "observability" {
  source       = "../../../modules/observability"
  name         = "${var.name_prefix}-observability"
  cluster_name = var.cluster_name
  tags         = var.tags
}
