locals {
  environment  = "qa"
  project_name = "microservices"
  name_prefix  = "acme-ms-qa"
  aws_region   = "us-east-1"
  account_id   = "222222222222"
  state_bucket = "acme-ms-terraform-state-qa"
  lock_table   = "terraform-locks"

  vpc_cidr = "10.20.0.0/16"

  eks = {
    node_instance_types    = ["t3.large"]
    min_size               = 2
    desired_size           = 2
    max_size               = 4
    endpoint_public_access = true
  }

  data = {
    postgres_instance_class    = "db.t4g.medium"
    multi_az                   = false
    deletion_protection        = false
    backup_retention_period    = 7
    documentdb_instance_count  = 1
    redis_replicas             = 1
    redis_automatic_failover   = true
    msk_broker_nodes           = 2
  }

  tags = {
    project      = "microservices"
    environment  = "qa"
    owner        = "platform-team"
    managed_by   = "terragrunt"
    cost_center  = "architecture-platform"
  }
}
