variable "cluster_identifier" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_ids" { type = list(string) }
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "master_username" {
  type    = string
  default = "docdbadmin"
}
variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "instance_count" {
  type    = number
  default = 1
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
  default = {
} }
