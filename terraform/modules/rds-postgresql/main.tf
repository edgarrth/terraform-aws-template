resource "random_password" "master" {
  length  = 24
  special = true
}

resource "aws_security_group" "this" {
  name   = "${var.identifier}-postgresql-sg"
  vpc_id = var.vpc_id
  ingress { from_port = 5432 to_port = 5432 protocol = "tcp" cidr_blocks = [var.vpc_cidr] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier                  = var.identifier
  engine                      = "postgres"
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  db_name                     = var.database_name
  username                    = var.master_username
  password                    = random_password.master.result
  db_subnet_group_name        = var.db_subnet_group_name
  vpc_security_group_ids      = [aws_security_group.this.id]
  storage_encrypted           = true
  kms_key_id                  = var.kms_key_arn
  multi_az                    = var.multi_az
  backup_retention_period     = var.backup_retention_period
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = !var.deletion_protection
  publicly_accessible         = false
  auto_minor_version_upgrade  = true
  tags                        = var.tags
}
