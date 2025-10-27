variable "name" {
  type = string
}

variable "environment" {
  type = string
}
 

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "username" {
  type = string
}

variable "password" {
  description = "RDS master/password (sensitive)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.password) >= 8 && length(var.password) <= 41
    error_message = "db password must be between 8 and 41 characters"
  }
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}