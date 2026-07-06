module "networking" {
  source                = "../../../../modules/network/networking"
  aws_region            = var.aws_region
  name_prefix           = local.name
  vpc_cidr              = "10.20.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs = ["10.20.0.0/24", "10.20.1.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
  database_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24"]
  enable_nat_gateway    = true
  tags                  = local.tags
}
