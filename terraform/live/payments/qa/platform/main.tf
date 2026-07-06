data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = { bucket = "acme-ms-terraform-state-qa", key = "payments/qa/foundation/terraform.tfstate", region = "us-east-1" }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = { bucket = "acme-ms-terraform-state-qa", key = "payments/qa/network/terraform.tfstate", region = "us-east-1" }
}

module "ecr" {
  source = "../../../../modules/platform/ecr"
  repositories = [
    "${local.name}/customer-service",
    "${local.name}/payment-service",
    "${local.name}/notification-service"
  ]
  kms_key_arn = data.terraform_remote_state.foundation.outputs.kms_key_arn
  tags        = local.tags
}

module "eks" {
  source               = "../../../../modules/platform/eks"
  name                 = "${local.name}-eks"
  vpc_id               = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids           = data.terraform_remote_state.network.outputs.private_subnet_ids
  cluster_role_arn     = data.terraform_remote_state.foundation.outputs.eks_cluster_role_arn
  node_role_arn        = data.terraform_remote_state.foundation.outputs.eks_node_role_arn
  node_instance_types  = ["t3.large"]
  min_size             = 1
  desired_size         = 2
  max_size             = 4
  endpoint_public_access = true
  tags                 = local.tags
}

module "waf" {
  source = "../../../../modules/platform/waf"
  name   = "${local.name}-waf"
  scope  = "REGIONAL"
  tags   = local.tags
}
