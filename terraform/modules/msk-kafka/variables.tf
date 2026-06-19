variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_ids" { type = list(string) }
variable "kafka_version" { type = string default = "3.6.0" }
variable "broker_instance_type" { type = string default = "kafka.t3.small" }
variable "number_of_broker_nodes" { type = number default = 2 }
variable "ebs_volume_size" { type = number default = 100 }
variable "tags" { type = map(string) default = {} }
