variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "key_name" { type = string }
variable "ami_id" { type = string }
variable "instance_type" {
  type = string
  default = "t3.micro"
}
variable "create_bastion" { 
    type = bool
    default = true
}
variable "tags" {
  type = map(string)
  default = {}
}