variable "name" { type = string }
variable "description" {
  type    = string
  default = "KMS key managed by Terraform"
}
variable "deletion_window_in_days" {
  type    = number
  default = 10
}
variable "enable_key_rotation" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {
} }
