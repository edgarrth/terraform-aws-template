locals {
  environment  = "prod"
  project_name = "microservices"
  name_prefix  = "acme-ms-prod"
  aws_region   = "us-east-1"
  account_id   = "333333333333"
  state_bucket = "acme-ms-terraform-state-prod"
  lock_table   = "terraform-locks"

  vpc_cidr = "10.30.0.0/16"

  eks = {
    node_instance_types    = ["m6i.large"]
    min_size               = 3
    desired_size           = 3
    max_size               = 10
    endpoint_public_access = false
  }

  data = {
    postgres_instance_class    = "db.r6g.large"
    multi_az                   = true
    deletion_protection        = true
    backup_retention_period    = 35
    documentdb_instance_count  = 3
    redis_replicas             = 2
    redis_automatic_failover   = true
    msk_broker_nodes           = 3
  }

  tags = {
    project      = "microservices"
    environment  = "prod"
    owner        = "platform-team"
    managed_by   = "terragrunt"
    cost_center  = "architecture-platform"
  }
}
