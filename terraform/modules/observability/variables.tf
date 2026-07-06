variable "name_prefix" { type = string }
variable "log_retention_days" { type = number default = 30 }
variable "create_container_log_group" { type = bool default = true }
variable "tags" { type = map(string) default = {} }
