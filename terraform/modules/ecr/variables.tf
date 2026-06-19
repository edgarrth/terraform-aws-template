variable "repositories" { type = list(string) }
variable "kms_key_arn" { type = string default = null }
variable "image_tag_mutability" { type = string default = "IMMUTABLE" }
variable "tags" { type = map(string) default = {} }
