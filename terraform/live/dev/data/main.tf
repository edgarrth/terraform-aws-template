data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = { bucket = "acme-ms-terraform-state-dev", key = "dev/foundation/terraform.tfstate", region = "us-east-1" }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = { bucket = "acme-ms-terraform-state-dev", key = "dev/network/terraform.tfstate", region = "us-east-1" }
}

module "postgresql" {
  source                  = "../../../modules/rds-postgresql"
  identifier              = "${local.name}-postgresql"
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                = data.terraform_remote_state.network.outputs.vpc_cidr
  db_subnet_group_name    = data.terraform_remote_state.network.outputs.db_subnet_group_name
  kms_key_arn             = data.terraform_remote_state.foundation.outputs.kms_key_arn
  instance_class          = "db.t4g.medium"
  multi_az                = false
  deletion_protection     = false
  backup_retention_period = 7
  tags                    = local.tags
}

module "documentdb" {
  source                  = "../../../modules/documentdb"
  cluster_identifier      = "${local.name}-documentdb"
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_ids              = data.terraform_remote_state.network.outputs.database_subnet_ids
  kms_key_arn             = data.terraform_remote_state.foundation.outputs.kms_key_arn
  instance_count          = 1
  deletion_protection     = false
  backup_retention_period = 7
  tags                    = local.tags
}

module "redis" {
  source                     = "../../../modules/elasticache-redis"
  name                       = "${local.name}-redis"
  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr                   = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_ids                 = data.terraform_remote_state.network.outputs.database_subnet_ids
  replicas_per_node_group    = 0
  automatic_failover_enabled = false
  tags                       = local.tags
}

module "msk" {
  source                 = "../../../modules/msk-kafka"
  name                   = "${local.name}-msk"
  vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr               = data.terraform_remote_state.network.outputs.vpc_cidr
  subnet_ids             = data.terraform_remote_state.network.outputs.private_subnet_ids
  number_of_broker_nodes = 2
  tags                   = local.tags
}

module "secrets" {
  source     = "../../../modules/secrets-manager"
  kms_key_id = data.terraform_remote_state.foundation.outputs.kms_key_id
  secrets = {
    "${local.name}/postgresql" = { description = "PostgreSQL credentials", secret_value = module.postgresql.secret_value_json }
    "${local.name}/documentdb" = { description = "DocumentDB credentials", secret_value = module.documentdb.secret_value_json }
  }
  tags = local.tags
}
