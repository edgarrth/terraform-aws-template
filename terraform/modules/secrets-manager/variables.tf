variable "secrets" {
  type = map(object({
    description  = optional(string, "Managed by Terraform")
    secret_value = string
  }))
  sensitive = true
}
variable "kms_key_id" { type = string default = null }
variable "tags" { type = map(string) default = {} }
