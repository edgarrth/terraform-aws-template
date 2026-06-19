module "networking" {
  source               = "../../../modules/networking"
  name                 = "${var.name_prefix}-vpc"
  vpc_cidr             = var.vpc_cidr
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnet_cidrs  = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 3)]
  private_subnet_cidrs = [cidrsubnet(var.vpc_cidr, 8, 11), cidrsubnet(var.vpc_cidr, 8, 12), cidrsubnet(var.vpc_cidr, 8, 13)]
  database_subnet_cidrs = [cidrsubnet(var.vpc_cidr, 8, 21), cidrsubnet(var.vpc_cidr, 8, 22), cidrsubnet(var.vpc_cidr, 8, 23)]
  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "prod"
  tags                 = var.tags
}
