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