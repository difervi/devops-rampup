output "bastion_public_ip" {
  value       = try(aws_instance.bastion[0].public_ip, "")
  description = "Public IP of the bastion"
}

output "bastion_instance_id" {
  value = try(aws_instance.bastion[0].id, "")
}

output "bastion_sg_id" {
  value       = try(aws_security_group.bastion_sg.id, "")
  description = "Security Group id for the bastion instances"
}
