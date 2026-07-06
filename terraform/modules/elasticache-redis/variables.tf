variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_ids" { type = list(string) }
variable "node_type" { type = string default = "cache.t4g.micro" }
variable "replicas_per_node_group" { type = number default = 1 }
variable "automatic_failover_enabled" { type = bool default = true }
variable "tags" { type = map(string) default = {} }
