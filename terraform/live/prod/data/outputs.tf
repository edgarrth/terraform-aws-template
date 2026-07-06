output "postgresql_endpoint" { value = module.postgresql.endpoint }
output "documentdb_endpoint" { value = module.documentdb.endpoint }
output "redis_primary_endpoint" { value = module.redis.primary_endpoint }
output "msk_bootstrap_brokers_sasl_iam" { value = module.msk.bootstrap_brokers_sasl_iam }
output "secret_arns" { value = module.secrets.secret_arns }
