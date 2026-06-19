locals {
  environment  = "dev"
  project_name = "microservices"
  name_prefix  = "acme-ms-dev"
  aws_region   = "us-east-1"
  account_id   = "111111111111"
  state_bucket = "acme-ms-terraform-state-dev"
  lock_table   = "terraform-locks"

  vpc_cidr = "10.10.0.0/16"

  eks = {
    node_instance_types    = ["t3.large"]
    min_size               = 1
    desired_size           = 1
    max_size               = 3
    endpoint_public_access = true
  }

  data = {
    postgres_instance_class    = "db.t4g.medium"
    multi_az                   = false
    deletion_protection        = false
    backup_retention_period    = 7
    documentdb_instance_count  = 1
    redis_replicas             = 0
    redis_automatic_failover   = false
    msk_broker_nodes           = 2
  }

  tags = {
    project      = "microservices"
    environment  = "dev"
    owner        = "platform-team"
    managed_by   = "terragrunt"
    cost_center  = "architecture-platform"
  }
}
