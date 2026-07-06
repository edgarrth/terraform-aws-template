module "networking" {
  source                = "../../../modules/networking"
  name_prefix           = local.name
  vpc_cidr              = "10.10.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
  database_subnet_cidrs = ["10.10.20.0/24", "10.10.21.0/24"]
  enable_nat_gateway    = true
  tags                  = local.tags
}
