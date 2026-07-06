data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = { bucket = "acme-ms-terraform-state-dev", key = "payments/dev/foundation/terraform.tfstate", region = "us-east-1" }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = { bucket = "acme-ms-terraform-state-dev", key = "payments/dev/network/terraform.tfstate", region = "us-east-1" }
}

module "postgresql" {
  source                  = "../../../../modules/data/aurora-postgresql"
  cluster_identifier      = "${local.name}-aurora-pg"
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                = data.terraform_remote_state.network.outputs.vpc_cidr
  db_subnet_group_name    = data.terraform_remote_state.network.outputs.db_subnet_group_name
  kms_key_arn             = data.terraform_remote_state.foundation.outputs.kms_key_arn
  instance_class          = var.environment == "prod" ? "db.r6g.large" : "db.t4g.medium"
  instance_count          = var.environment == "prod" ? 2 : 1
  deletion_protection     = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 14 : 7
  tags                    = local.tags
}

module "documentdb" {
  source                  = "../../../../modules/data/documentdb"
  cluster_identifier      = "${local.name}-documentdb"
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_ids              = data.terraform_remote_state.network.outputs.database_subnet_ids
  kms_key_arn             = data.terraform_remote_state.foundation.outputs.kms_key_arn
  instance_count          = var.environment == "prod" ? 2 : 1
  deletion_protection     = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 14 : 7
  tags                    = local.tags
}

module "redis" {
  source                     = "../../../../modules/data/elasticache-redis"
  name                       = "${local.name}-redis"
  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                   = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_ids                 = data.terraform_remote_state.network.outputs.database_subnet_ids
  replicas_per_node_group    = 0
  automatic_failover_enabled = false
  tags                       = local.tags
}

module "msk" {
  source                 = "../../../../modules/data/msk-kafka"
  name                   = "${local.name}-msk"
  vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr               = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_ids             = data.terraform_remote_state.network.outputs.private_subnet_ids
  number_of_broker_nodes = 2
  tags                   = local.tags
}

module "dynamodb" {
  source                         = "../../../../modules/data/dynamodb"
  name                           = "${local.name}-merchant-profile-ddb"
  kms_key_arn                    = data.terraform_remote_state.foundation.outputs.kms_key_arn
  point_in_time_recovery_enabled = var.environment == "prod" ? true : false
  tags                           = merge(local.tags, { component = "dynamodb", finops_allocation = "direct", backup_required = var.environment == "prod" ? "true" : "false" })
}

module "messaging" {
  source      = "../../../../modules/data/messaging"
  name_prefix = local.name
  kms_key_arn = data.terraform_remote_state.foundation.outputs.kms_key_arn
  tags        = merge(local.tags, { component = "messaging", finops_allocation = "shared" })
}

module "secrets" {
  source     = "../../../../modules/data/secrets-manager"
  kms_key_id = data.terraform_remote_state.foundation.outputs.kms_key_id
  secrets = {
    "${local.name}/postgresql" = { description = "PostgreSQL credentials", secret_value = module.postgresql.secret_value_json }
    "${local.name}/documentdb" = { description = "DocumentDB credentials", secret_value = module.documentdb.secret_value_json }
  }
  tags = local.tags
}
