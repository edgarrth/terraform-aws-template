module "networking" {
  source                = "../../../../modules/network/networking"
  aws_region            = var.aws_region
  name_prefix           = local.name
  vpc_cidr              = "10.30.0.0/16"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
  private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
  database_subnet_cidrs = ["10.30.20.0/24", "10.30.21.0/24", "10.30.22.0/24"]
  enable_nat_gateway    = true
  tags                  = local.tags
}
