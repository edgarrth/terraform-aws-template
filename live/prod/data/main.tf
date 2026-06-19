module "postgresql" {
  source                  = "../../../modules/rds-postgresql"
  identifier              = "${var.name_prefix}-postgresql"
  vpc_id                  = var.vpc_id
  vpc_cidr                = var.vpc_cidr
  db_subnet_group_name    = var.db_subnet_group_name
  kms_key_arn             = var.kms_key_arn
  instance_class          = var.postgres_instance_class
  multi_az                = var.multi_az
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period
  tags                    = var.tags
}

module "documentdb" {
  source                  = "../../../modules/documentdb"
  cluster_identifier      = "${var.name_prefix}-documentdb"
  vpc_id                  = var.vpc_id
  vpc_cidr                = var.vpc_cidr
  subnet_ids              = var.database_subnet_ids
  kms_key_arn             = var.kms_key_arn
  instance_count          = var.documentdb_instance_count
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period
  tags                    = var.tags
}

module "redis" {
  source                     = "../../../modules/elasticache-redis"
  name                       = "${var.name_prefix}-redis"
  vpc_id                     = var.vpc_id
  vpc_cidr                   = var.vpc_cidr
  subnet_ids                 = var.database_subnet_ids
  replicas_per_node_group    = var.redis_replicas
  automatic_failover_enabled = var.redis_automatic_failover
  tags                       = var.tags
}

module "msk" {
  source                 = "../../../modules/msk-kafka"
  name                   = "${var.name_prefix}-msk"
  vpc_id                 = var.vpc_id
  vpc_cidr               = var.vpc_cidr
  subnet_ids             = var.private_subnet_ids
  number_of_broker_nodes = var.msk_broker_nodes
  tags                   = var.tags
}

module "secrets" {
  source     = "../../../modules/secrets-manager"
  kms_key_id = var.kms_key_id
  secrets = {
    "${var.name_prefix}/postgresql" = { description = "PostgreSQL credentials", secret_value = module.postgresql.secret_value_json }
    "${var.name_prefix}/documentdb" = { description = "DocumentDB credentials", secret_value = module.documentdb.secret_value_json }
  }
  tags = var.tags
}
