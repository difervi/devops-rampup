module "network" {
  source = "../../modules/network"

  name                    = var.name
  vpc_cidr                = var.vpc_cidr
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  map_public_ip_on_launch = var.map_public_ip_on_launch
  enable_nat              = var.enable_nat
  tags                    = var.tags
}
