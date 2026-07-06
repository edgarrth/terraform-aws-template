variable "name" { type = string }
variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}
variable "hash_key" {
  type    = string
  default = "pk"
}
variable "range_key" {
  type    = string
  default = "sk"
}
variable "point_in_time_recovery_enabled" {
  type    = bool
  default = true
}
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
