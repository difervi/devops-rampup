
data "aws_ssm_parameter" "amzn2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_security_group" "bastion_sg" {
  name   = "${var.name_prefix}-bastion-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { "Name" = "${var.name_prefix}-bastion-${var.environment}" })
}

resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  # Use provided AMI if set; otherwise fall back to the SSM-provided Amazon Linux 2 AMI
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.amzn2.value
  instance_type               = var.instance_type
  subnet_id                   = element(var.public_subnet_ids, 0)
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  tags = merge(var.tags, { "Name" = "${var.name_prefix}-bastion-${var.environment}" })
}