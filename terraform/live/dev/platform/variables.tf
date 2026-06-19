variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "common_tags" { type = map(string) default = {} }

locals {
  name = "${var.name_prefix}-${var.environment}"
  tags = merge(var.common_tags, {
    environment = var.environment
  })
}
