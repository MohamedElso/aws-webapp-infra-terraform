variable "name_prefix" {}
variable "vpc_id" {}
variable "subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "container_port" {}
variable "domain_name" { default = "" }
variable "certificate_arn" { default = "" }
variable "tags" { type = map(string) }
