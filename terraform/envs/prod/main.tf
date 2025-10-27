data "aws_ssm_parameter" "amzn2" {
     name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
resource "aws_security_group" "db_sg" {
  name   = "${var.name}-db-sg-${var.environment}"
  vpc_id = module.network.vpc_id

  # permite tráfico MySQL desde el app security group (ajustar)
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # app_sg definido abajo
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Security Group para las instancias de aplicación (app servers)
resource "aws_security_group" "app_sg" {
  name   = "${var.name}-app-sg-${var.environment}"
  vpc_id = module.network.vpc_id

  ingress {
    description = "Allow HTTP from anywhere (or ALB)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["200.118.60.244/0"]
  }

  tags = var.tags
}

module "db" {
  source = "../../modules/db"

  name                 = var.name
  environment          = var.name
  subnet_ids           = module.network.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  username             = var.db_username
  password             = var.db_password   
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  engine_version       = var.db_engine_version
  multi_az             = var.db_multi_az
  tags                 = var.tags
}