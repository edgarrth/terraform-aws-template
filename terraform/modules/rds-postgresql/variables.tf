variable "identifier" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "db_subnet_group_name" { type = string }
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "engine_version" {
  type    = string
  default = "16.3"
}
variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "allocated_storage" {
  type    = number
  default = 50
}
variable "database_name" {
  type    = string
  default = "appdb"
}
variable "master_username" {
  type    = string
  default = "appadmin"
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
