include "root" { path = find_in_parent_folders() }
locals { env_config = read_terragrunt_config(find_in_parent_folders("env.hcl")) }

dependency "foundation" { config_path = "../foundation" }
dependency "network" { config_path = "../network" }

inputs = {
  vpc_id                    = dependency.network.outputs.vpc_id
  vpc_cidr                  = dependency.network.outputs.vpc_cidr
  private_subnet_ids        = dependency.network.outputs.private_subnet_ids
  database_subnet_ids       = dependency.network.outputs.database_subnet_ids
  db_subnet_group_name      = dependency.network.outputs.db_subnet_group_name
  kms_key_arn               = dependency.foundation.outputs.kms_key_arn
  kms_key_id                = dependency.foundation.outputs.kms_key_id
  postgres_instance_class   = local.env_config.locals.data.postgres_instance_class
  multi_az                  = local.env_config.locals.data.multi_az
  deletion_protection       = local.env_config.locals.data.deletion_protection
  backup_retention_period   = local.env_config.locals.data.backup_retention_period
  documentdb_instance_count = local.env_config.locals.data.documentdb_instance_count
  redis_replicas            = local.env_config.locals.data.redis_replicas
  redis_automatic_failover  = local.env_config.locals.data.redis_automatic_failover
  msk_broker_nodes          = local.env_config.locals.data.msk_broker_nodes
}
