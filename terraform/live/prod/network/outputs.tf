output "vpc_id" { value = module.networking.vpc_id }
output "vpc_cidr" { value = module.networking.vpc_cidr }
output "public_subnet_ids" { value = module.networking.public_subnet_ids }
output "private_subnet_ids" { value = module.networking.private_subnet_ids }
output "database_subnet_ids" { value = module.networking.database_subnet_ids }
output "db_subnet_group_name" { value = module.networking.db_subnet_group_name }
