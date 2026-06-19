output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "database_subnet_ids" { value = [for s in aws_subnet.database : s.id] }
output "db_subnet_group_name" { value = aws_db_subnet_group.database.name }
