include "root" { path = find_in_parent_folders() }
locals { env_config = read_terragrunt_config(find_in_parent_folders("env.hcl")) }

dependency "foundation" { config_path = "../foundation" }
dependency "network" { config_path = "../network" }

inputs = {
  vpc_id                 = dependency.network.outputs.vpc_id
  private_subnet_ids     = dependency.network.outputs.private_subnet_ids
  kms_key_arn            = dependency.foundation.outputs.kms_key_arn
  eks_cluster_role_arn   = dependency.foundation.outputs.eks_cluster_role_arn
  eks_node_role_arn      = dependency.foundation.outputs.eks_node_role_arn
  node_instance_types    = local.env_config.locals.eks.node_instance_types
  min_size               = local.env_config.locals.eks.min_size
  desired_size           = local.env_config.locals.eks.desired_size
  max_size               = local.env_config.locals.eks.max_size
  endpoint_public_access = local.env_config.locals.eks.endpoint_public_access
}
