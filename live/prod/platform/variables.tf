variable "environment" { type = string }
variable "project_name" { type = string }
variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "account_id" { type = string }
variable "tags" { type = map(string) }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "kms_key_arn" { type = string }
variable "eks_cluster_role_arn" { type = string }
variable "eks_node_role_arn" { type = string }
variable "node_instance_types" { type = list(string) }
variable "min_size" { type = number }
variable "desired_size" { type = number }
variable "max_size" { type = number }
variable "endpoint_public_access" { type = bool }
