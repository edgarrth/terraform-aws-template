variable "name_prefix" { type = string }
variable "kms_key_arn" {
  type    = string
  default = null
}
variable "queue_retention_seconds" {
  type    = number
  default = 345600
}
variable "dlq_retention_seconds" {
  type    = number
  default = 1209600
}
variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {
} }
