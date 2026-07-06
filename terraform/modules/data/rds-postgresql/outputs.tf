output "endpoint" { value = aws_db_instance.this.endpoint }
output "port" { value = aws_db_instance.this.port }
output "secret_value_json" {
  value = jsonencode({ username = var.master_username, password = random_password.master.result, host = aws_db_instance.this.address, port = aws_db_instance.this.port, database = var.database_name })
  sensitive = true
}
output "security_group_id" { value = aws_security_group.this.id }
