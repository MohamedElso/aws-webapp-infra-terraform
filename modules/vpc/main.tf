module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = var.name
  cidr    = var.vpc_cidr
  azs     = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = var.tags
}
