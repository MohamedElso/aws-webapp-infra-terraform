variable "name_prefix" {}
variable "cluster_id" {}
variable "task_definition_arn" {}
variable "desired_count" {}
variable "container_port" {}
variable "private_subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "target_group_arn" {}
variable "tags" { type = map(string) }
