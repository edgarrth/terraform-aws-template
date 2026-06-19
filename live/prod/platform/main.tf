module "ecr" {
  source = "../../../modules/ecr"
  repositories = [
    "${var.name_prefix}/customer-service",
    "${var.name_prefix}/payment-service",
    "${var.name_prefix}/notification-service"
  ]
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "eks" {
  source                 = "../../../modules/eks"
  name                   = "${var.name_prefix}-eks"
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  cluster_role_arn       = var.eks_cluster_role_arn
  node_role_arn          = var.eks_node_role_arn
  node_instance_types    = var.node_instance_types
  min_size               = var.min_size
  desired_size           = var.desired_size
  max_size               = var.max_size
  endpoint_public_access = var.endpoint_public_access
  tags                   = var.tags
}

module "waf" {
  source = "../../../modules/waf"
  name   = "${var.name_prefix}-waf"
  scope  = "REGIONAL"
  tags   = var.tags
}
