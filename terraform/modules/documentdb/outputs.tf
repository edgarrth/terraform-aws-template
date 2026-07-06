output "endpoint" { value = aws_docdb_cluster.this.endpoint }
output "port" { value = aws_docdb_cluster.this.port }
output "secret_value_json" {
  value = jsonencode({ username = var.master_username, password = random_password.master.result, host = aws_docdb_cluster.this.endpoint, port = aws_docdb_cluster.this.port })
  sensitive = true
}
output "security_group_id" { value = aws_security_group.this.id }
