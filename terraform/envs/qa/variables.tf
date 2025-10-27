variable "name" {
  description = "Nombre del entorno"
  type        = string
  default     = "movie-qa"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "List of availability zones (leave empty to auto-select)"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks (one per AZ)"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks (one per AZ)"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "map_public_ip_on_launch" {
  description = "If new instances in public subnets should get a public IP"
  type        = bool
  default     = true
}

variable "enable_nat" {
  description = "Create a NAT instance for private subnets (disabled for QA to save costs)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default = {
    Project     = "movie-analyst"
    Environment = "qa"
  }
  
}
variable "key_name" {
  description = "Name of the SSH keypair to use for instances"
  type        = string
  default     = "devops-rampup-key" 
}

variable "ami_id" {
  description = "AMI id to use for EC2 instances"
  type        = string
  default     = "" 
}

variable "instance_type" {
  description = "EC2 instance type for compute instances"
  type        = string
  default     = "t3.micro"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "admin"
}


variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "8.0"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS (false for QA to save costs)"
  type        = bool
  default     = false
}
variable "environment" {
  description = "Deployment environment (e.g., dev, qa, prod)"
  type        = string
  default     = "qa"
}
variable "db_password" {
  description = "RDS admin password (sensitive) - I use secretsmanager"
  type        = string
  sensitive   = true
  default     = ""
}

variable "use_secrets_manager" {
  description = "If true, read DB password from AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret to read the DB password from"
  type        = string
  default     = ""
}
