variable "name_prefix" {}
variable "container_image" {}
variable "container_port" {}
variable "cpu" {}
variable "memory" {}
variable "log_group_name" {}
variable "region" {}
variable "execution_role_arn" {}
variable "task_role_arn" {}
variable "tags" { type = map(string) }
