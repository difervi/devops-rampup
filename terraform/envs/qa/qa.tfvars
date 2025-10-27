
name = "devops-qa"
environment = "qa"


vpc_cidr = "10.10.0.0/16"
public_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnets = ["10.10.101.0/24", "10.10.102.0/24"]


key_name = "devops-rampup-key"
ami_id = "ami-057a9f77fd28e08c5"
instance_type = "t3.micro"

db_username = "admin"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_engine_version = "8.0"
db_multi_az = false

tags = {
  Project     = "movie-analyst"
  environment = "qa"
}

use_secrets_manager = true
secrets_manager_secret_name = "devops-qa-db-password"
db_password = ""