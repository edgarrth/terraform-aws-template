resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name}-redis-subnet-group" })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-redis-sg"
  description = "Redis security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-redis-sg" })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = var.name
  description                = "Redis for ${var.name}"
  engine                     = "redis"
  node_type                  = var.node_type
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  num_node_groups            = 1
  replicas_per_node_group    = var.replicas_per_node_group
  automatic_failover_enabled = var.automatic_failover_enabled
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = merge(var.tags, { Name = var.name })
}
