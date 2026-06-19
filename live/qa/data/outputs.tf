output "postgres_endpoint" { value = module.postgresql.endpoint }
output "documentdb_endpoint" { value = module.documentdb.endpoint }
output "redis_primary_endpoint" { value = module.redis.primary_endpoint_address }
output "msk_bootstrap_brokers" { value = module.msk.bootstrap_brokers }
