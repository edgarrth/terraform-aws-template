output "endpoint" { value = aws_rds_cluster.this.endpoint }
output "reader_endpoint" { value = aws_rds_cluster.this.reader_endpoint }
output "port" { value = aws_rds_cluster.this.port }
output "security_group_id" { value = aws_security_group.this.id }
output "secret_value_json" {
  value     = jsonencode({ username = var.master_username, password = random_password.master.result, host = aws_rds_cluster.this.endpoint, reader_host = aws_rds_cluster.this.reader_endpoint, port = aws_rds_cluster.this.port, database = var.database_name })
  sensitive = true
}
