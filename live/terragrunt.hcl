# Root Terragrunt configuration inherited by all live/*/* components.
locals {
  env_config   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_config.locals.environment
  project_name = local.env_config.locals.project_name
  name_prefix  = local.env_config.locals.name_prefix
  aws_region   = local.env_config.locals.aws_region
  account_id   = local.env_config.locals.account_id
  state_bucket = local.env_config.locals.state_bucket
  lock_table   = local.env_config.locals.lock_table
  tags         = local.env_config.locals.tags
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = local.lock_table
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = ${jsonencode(local.tags)}
  }
}
EOF
}

inputs = {
  environment  = local.environment
  project_name = local.project_name
  name_prefix  = local.name_prefix
  aws_region   = local.aws_region
  account_id   = local.account_id
  tags         = local.tags
}
