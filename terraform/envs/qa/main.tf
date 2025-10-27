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

module "compute" {
  source = "../../modules/compute"

  name_prefix        = var.name
  environment        = var.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  key_name           = var.key_name                
  ami_id             = var.ami_id                  
  instance_type      = var.instance_type
  tags               = var.tags
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.name}-rds-sg-${var.environment}"
  vpc_id = module.network.vpc_id

  ingress {
    description = "Allow MySQL from private subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { "Name" = "${var.name}-rds-sg-${var.environment}" })
}

module "db" {
  source = "../../modules/db"

  name                 = var.name
  environment          = var.name
  subnet_ids           = module.network.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Password is taken from Secrets Manager when use_secrets_manager = true,
  # otherwise falls back to var.db_password.
  username             = var.db_username
  password             = local.db_password

  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  engine_version       = var.db_engine_version
  multi_az             = var.db_multi_az

  tags                 = var.tags
}
// Optional: read DB password from Secrets Manager if enabled
data "aws_secretsmanager_secret" "db" {
  count = var.use_secrets_manager && var.secrets_manager_secret_name != "" ? 1 : 0
  name  = var.secrets_manager_secret_name
}

data "aws_secretsmanager_secret_version" "db" {
  count     = var.use_secrets_manager && var.secrets_manager_secret_name != "" ? 1 : 0
  secret_id = try(data.aws_secretsmanager_secret.db[0].id, "")
}

locals {
  db_secret_raw = var.use_secrets_manager && var.secrets_manager_secret_name != "" ? data.aws_secretsmanager_secret_version.db[0].secret_string : ""
  db_password = (
    var.use_secrets_manager && var.secrets_manager_secret_name != "" ? (
      can(jsondecode(local.db_secret_raw)) ? try(jsondecode(local.db_secret_raw).password, local.db_secret_raw) : local.db_secret_raw
    ) : var.db_password
  )
}

# Allow MySQL from the bastion security group (SG->SG) — preferred over IP rules.
resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = module.compute.bastion_sg_id
  description              = "Allow MySQL from bastion security group"
}