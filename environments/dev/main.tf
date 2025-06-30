provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source             = "../../modules/vpc"
  name               = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  azs                = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  tags               = var.tags
}

module "iam_roles" {
  source           = "../../modules/iam_roles"
  name_prefix      = var.name_prefix
  vpc_id           = module.vpc.vpc_id
  container_port   = var.container_port
  tags             = var.tags
}

module "acm" {
  source         = "../../modules/acm"
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
}

module "alb" {
  source            = "../../modules/alb"
  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnets           = module.vpc.public_subnets
  security_groups   = [module.iam_roles.alb_sg_id]
  container_port    = var.container_port
  domain_name       = var.domain_name
  certificate_arn   = module.acm.certificate_arn
  tags              = var.tags
}

module "ecs_cluster" {
  source      = "../../modules/ecs_cluster"
  name_prefix = var.name_prefix
  tags        = var.tags
}

module "ecs_task_definition" {
  source             = "../../modules/ecs_task_definition"
  name_prefix        = var.name_prefix
  container_image    = var.container_image
  container_port     = var.container_port
  cpu                = var.container_cpu
  memory             = var.container_memory
  log_group_name     = "/ecs/${var.name_prefix}-dev"
  region             = var.aws_region
  execution_role_arn = module.iam_roles.task_execution_role_arn
  task_role_arn      = module.iam_roles.task_role_arn
  tags               = var.tags
}

module "ecs_service" {
  source              = "../../modules/ecs_service"
  name_prefix         = var.name_prefix
  cluster_id          = module.ecs_cluster.cluster_id
  task_definition_arn = module.ecs_task_definition.task_definition_arn
  desired_count       = var.desired_count
  container_port      = var.container_port
  private_subnets     = module.vpc.private_subnets
  security_groups     = [module.iam_roles.ecs_sg_id]
  target_group_arn    = module.alb.target_group_arn
  tags                = var.tags
}
