variable "name" { type = string }
variable "scope" {
  type    = string
  default = "REGIONAL"
}
variable "tags" {
  type    = map(string)
  default = {
} }
